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
  # its 1password asks there. The panes of the launchd herdr/tmux live in the
  # gui session (for the keychain) and don't inherit a login's SSH_AUTH_SOCK,
  # but a unix socket doesn't care about the security session. So every login
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

  # Run by /etc/ssh/sshrc (the ssh-agents darwin module) in every login's
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
        login still connected first, the local 1password agent last (macOS)
      '';
      socket = lib.mkOption {
        type = lib.types.str;
        readOnly = true;
        default = "${home}/.ssh/agent.sock";
        description = ''
          The proxy's socket, for SSH_AUTH_SOCK in environments that don't get
          the session variables (launchd agents).
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

            # workstations
            desktop = florian "192.168.48.10";
            macbook = florian "192.168.48.11";
            # forwarded so its keys come from the machine in front of you, see
            # forwardedAgents; not from the mini itself, it would hand the
            # proxy to itself
            macmini =
              florian "192.168.48.124" // lib.optionalAttrs (!hub.enable) { ForwardAgent = ''"${agent}"''; };

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
        assertions = [
          {
            assertion = isDarwin;
            message = "custom.ssh.forwardedAgents only knows macOS (launchd, 1password's socket path)";
          }
        ];

        # not inside an ssh login, which keeps the agent it forwards itself
        home.sessionVariablesExtra = ''
          [ -n "''${SSH_CONNECTION-}" ] || export SSH_AUTH_SOCK=${lib.escapeShellArg hub.socket}
        '';

        launchd.agents.ssh-agent-proxy = {
          enable = true;
          config = {
            ProgramArguments = [ (lib.getExe agentProxy) ];
            RunAtLoad = true;
            KeepAlive = true;
          };
        };
      })
    ]
  );
}
