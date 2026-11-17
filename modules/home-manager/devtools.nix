{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.custom.devtools;
  inherit (pkgs.stdenv.hostPlatform) isDarwin;

  # the service gets a bare environment (launchd, the systemd user manager);
  # devtools reads git state and asks herdr or tmux for the open sessions
  path = lib.makeBinPath (
    [
      pkgs.devtools
      pkgs.git
    ]
    ++ lib.optional config.custom.herdr.enable config.programs.herdr.package
    ++ lib.optional config.custom.tmux.enable pkgs.tmux
  );

  args = [
    (lib.getExe' pkgs.devtools "devtools")
    "serve"
    "--name"
    cfg.serve.name
  ];
in
{
  options.custom.devtools.serve = {
    enable = lib.mkEnableOption "answer the devtools switchers on the other machines with this machine's projects";
    name = lib.mkOption {
      type = lib.types.str;
      example = "macmini";
      description = ''
        What the switchers on the other machines call this one. devtools
        reaches it over ssh by the same name, so it should be the ssh alias
        the ssh module gives it.
      '';
    };
  };

  # Every machine answers a UDP broadcast on the LAN with where to read its
  # worktrees and sessions (port 47390, UDP and TCP), so the switcher lists
  # the projects of every machine that is awake without logging in anywhere;
  # only switching to one goes over ssh.
  config = lib.mkIf cfg.serve.enable {
    home.packages = [ pkgs.devtools ];

    systemd.user.services.devtools-serve = lib.mkIf (!isDarwin) {
      Unit.Description = "devtools serve: this machine's projects for the other machines";
      Install.WantedBy = [ "default.target" ];
      Service = {
        ExecStart = lib.escapeShellArgs args;
        Environment = [ "PATH=${path}" ];
        Restart = "on-failure";
        RestartSec = 5;
      };
    };

    # in the gui session, next to the herdr server it asks for the sessions
    launchd.agents.devtools-serve = lib.mkIf isDarwin {
      enable = true;
      config = {
        ProgramArguments = args;
        EnvironmentVariables.PATH = "${path}:/usr/bin:/bin";
        RunAtLoad = true;
        KeepAlive = true;
        ProcessType = "Background";
        StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/devtools-serve.log";
      };
    };
  };
}
