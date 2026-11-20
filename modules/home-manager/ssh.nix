# ssh client: keys come from the 1password agent, hosts shared by all
# machines live here, machine specific ones in hosts/<name>/home.nix
{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.custom.ssh;
  hub = cfg.forwardedAgents;
  inherit (pkgs.stdenv.hostPlatform) isDarwin;
  home = config.home.homeDirectory;

  root = hostname: {
    HostName = hostname;
    User = "root";
  };
  florian = hostname: {
    HostName = hostname;
    User = "florian";
  };

  # 1password's agent on this machine
  onePasswordAgent =
    if isDarwin then
      "${home}/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
    else
      "${home}/.1password/agent.sock";

  # Logged in over ssh, a key should come from the machine in front of you, so
  # its 1password asks there, not the one here, which may be locked. The panes
  # of the devtools server (and on macOS of the tmux server) are started by
  # launchd/systemd and don't inherit a login's SSH_AUTH_SOCK; on macOS they
  # even live in the gui session (for the keychain), but a unix socket doesn't
  # care about the security session. So every login
  # registers its forwarded agent (registerAgent below), and a proxy at a
  # fixed path, which everything here uses, hands each connection to the
  # newest one still alive, dropping dead ones on the way, and to the local
  # 1password when no login forwards one.
  registry = "${home}/.ssh/agents";

  pickAgent = pkgs.writeShellApplication {
    name = "ssh-agent-pick";
    runtimeInputs = [
      pkgs.socat
      pkgs.coreutils
    ];
    text = ''
      shopt -s nullglob
      # named <epoch nanoseconds>.<pid>, fixed width, so the glob sorts them
      # oldest first
      logins=(${lib.escapeShellArg registry}/*)
      for ((i = ''${#logins[@]} - 1; i >= 0; i--)); do
        agent=''${logins[i]}
        # sshd removes the socket when the login ends, connecting also
        # catches the ones left behind when it couldn't; never the proxy
        # itself, it would hand each connection back to itself
        if [[ $(readlink "$agent") != ${lib.escapeShellArg hub.socket} ]] \
          && socat -u OPEN:/dev/null "UNIX-CONNECT:$agent" 2>/dev/null; then
          exec socat STDIO "UNIX-CONNECT:$agent"
        fi
        rm -f "$agent"
      done
      exec socat STDIO UNIX-CONNECT:${lib.escapeShellArg onePasswordAgent}
    '';
  };

  agentProxy = pkgs.writeShellApplication {
    name = "ssh-agent-proxy";
    runtimeInputs = [ pkgs.socat ];
    text = ''
      umask 077
      exec socat UNIX-LISTEN:${lib.escapeShellArg hub.socket},fork,unlink-early EXEC:${lib.getExe pickAgent}
    '';
  };

  # Run by /etc/ssh/sshrc (modules/shared/ssh-agents.nix) in every login's
  # environment, sftp/scp included. Not ~/.ssh/rc: sshd runs that through the
  # login shell, whose zshenv has already put the proxy into SSH_AUTH_SOCK,
  # and skips it for sftp. It must not print, that would end up in scp/sftp
  # streams.
  registerAgent = pkgs.writeShellScript "ssh-register-agent" ''
    [ -S "''${SSH_AUTH_SOCK-}" ] || exit 0
    [ "$SSH_AUTH_SOCK" = ${lib.escapeShellArg hub.socket} ] && exit 0
    # a login from this machine to itself would hand the proxy to itself
    set -- $SSH_CONNECTION
    [ "$1" = "$3" ] && exit 0
    ${lib.getExe' pkgs.coreutils "mkdir"} -p -m 700 ${lib.escapeShellArg registry}
    # the picker only drops dead logins newer than the first live one, so
    # tidy up here: dead logins, and this one's agent registered by another
    # of its sessions, which moves up to here
    for entry in ${lib.escapeShellArg registry}/*; do
      if [ ! -S "$entry" ] || [ "$(${lib.getExe' pkgs.coreutils "readlink"} "$entry")" = "$SSH_AUTH_SOCK" ]; then
        ${lib.getExe' pkgs.coreutils "rm"} -f "$entry"
      fi
    done
    ${lib.getExe' pkgs.coreutils "ln"} -sf "$SSH_AUTH_SOCK" \
      ${lib.escapeShellArg registry}/"$(${lib.getExe' pkgs.coreutils "date"} +%s%N).$$"
  '';

  # what ssh and git use here, and what a login from here forwards
  agent = if hub.enable then hub.socket else onePasswordAgent;
in
{
  options.custom.ssh = {
    enable = lib.mkEnableOption "enable ssh";

    forwardedAgents = {
      enable = lib.mkEnableOption ''
        taking ssh keys from the agents forwarded by ssh logins, the newest
        login still connected first, the local 1password agent last
      '';
      socket = lib.mkOption {
        type = lib.types.str;
        readOnly = true;
        default = "${home}/.ssh/agent.sock";
        description = ''
          The proxy's socket, for SSH_AUTH_SOCK in environments that don't get
          the session variables (launchd agents, systemd user services).
        '';
      };
      registerScript = lib.mkOption {
        type = lib.types.package;
        readOnly = true;
        internal = true;
        default = registerAgent;
        description = "Registers a login's forwarded agent, run from /etc/ssh/sshrc.";
      };
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        programs.ssh = {
          enable = true;
          # the old defaults only restate what openssh does anyway
          enableDefaultConfig = false;

          # the hosts of the xcloud clusters, with their host keys
          includes = [ "${inputs.xcloud.packages.${pkgs.stdenv.hostPlatform.system}.ssh-config}" ];

          settings = {
            "*".IdentityAgent = ''"${agent}"'';

            # workstations; the agent is forwarded so the keys come from the
            # machine in front of you, see forwardedAgents. A machine with
            # forwarded agents forwards its proxy, so the keys follow a chain
            # (macbook -> desktop -> mini), but two such machines must never
            # forward to each other: each proxy would hand the connection to
            # the other, round and round. Hence the mini takes agents from
            # everyone (a login of the mini to itself is skipped by
            # registerAgent), the desktop only from machines without forwarded
            # agents (the macbook)
            desktop =
              florian "192.168.48.10" // lib.optionalAttrs (!hub.enable) { ForwardAgent = ''"${agent}"''; };
            macbook = florian "192.168.48.11";
            macmini = florian "192.168.48.124" // {
              ForwardAgent = ''"${agent}"'';
            };

            server = {
              HostName = "192.168.1.113";
              User = "nix";
            };

            # incus containers on the server, see hosts/containers and infra/
            hermes = root "172.16.0.132";
            apollo = root "172.16.0.233";
            hestia = root "172.16.0.92";
            aphrodite = root "172.16.0.52";

            localhost.StrictHostKeyChecking = false;
          };
        };
      }

      (lib.mkIf hub.enable {
        # not inside an ssh login, which keeps the agent it forwards itself
        home.sessionVariablesExtra = ''
          [ -n "''${SSH_CONNECTION-}" ] || export SSH_AUTH_SOCK=${lib.escapeShellArg hub.socket}
        '';

        launchd.agents.ssh-agent-proxy = lib.mkIf isDarwin {
          enable = true;
          config = {
            ProgramArguments = [ (lib.getExe agentProxy) ];
            RunAtLoad = true;
            KeepAlive = true;
          };
        };

        # with lingering (hosts/desktop) up from boot, before anyone logs in
        systemd.user.services.ssh-agent-proxy = lib.mkIf (!isDarwin) {
          Unit.Description = "ssh agent proxy: forwarded agents first, then 1password";
          Install.WantedBy = [ "default.target" ];
          Service = {
            ExecStart = lib.getExe agentProxy;
            Restart = "always";
            RestartSec = 1;
          };
        };
      })
    ]
  );
}
