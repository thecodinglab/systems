# CLIProxyAPI as a launchd daemon: exposes the OAuth logins of claude code,
# codex, ... as Anthropic/OpenAI/Gemini compatible APIs (counterpart of the
# nixos module services.cliproxyapi, which is systemd only)
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.cliproxyapi;
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;

  format = pkgs.formats.json { };
  home = "/Users/${cfg.user}";
  configFile = "${cfg.stateDir}/config.yaml";

  # yaml is a superset of json
  settings = format.generate "cliproxyapi.json" (
    lib.recursiveUpdate {
      config-version = 8;
      oauth.auth-dir = cfg.dataDir;
      management = {
        disable-control-panel = !hasManagementKey;
        # served from the store (MANAGEMENT_STATIC_PATH), never downloaded
        disable-auto-update-panel = true;
      };
    } cfg.settings
  );

  # the keys are only read at runtime, so they never end up in the store
  hasManagementKey = cfg.managementKeyFile != null;
  keyFiles = [ cfg.apiKeyFile ] ++ lib.optional hasManagementKey cfg.managementKeyFile;
  jqArgs = [
    "--rawfile"
    "key"
    cfg.apiKeyFile
  ]
  ++ lib.optionals hasManagementKey [
    "--rawfile"
    "management"
    cfg.managementKeyFile
  ]
  ++ [
    (
      ''.access."api-keys" = [$key | rtrimstr("\n")]''
      + lib.optionalString hasManagementKey '' | .management."secret-key" = ($management | rtrimstr("\n"))''
    )
  ];

  # the daemon and logins started by hand (`cliproxyapi --claude-login`) share
  # the paths; without WRITABLE_PATH the server writes logs/ and the like to
  # its working directory
  package = pkgs.symlinkJoin {
    inherit (cfg.package) pname version meta;
    paths = [ cfg.package ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/cliproxyapi \
        --set WRITABLE_PATH ${lib.escapeShellArg cfg.stateDir} \
        --set MANAGEMENT_STATIC_PATH ${cfg.panelPackage}/share/cliproxyapi/management.html \
        --add-flags "-config ${lib.escapeShellArg configFile}"
    '';
  };
in
{
  options.services.cliproxyapi = {
    enable = mkEnableOption "CLIProxyAPI as a launchd daemon";

    package = lib.mkPackageOption pkgs "cliproxyapi" { };

    panelPackage = lib.mkPackageOption pkgs "cliproxyapi-management-center" { };

    user = mkOption {
      type = types.str;
      default = config.system.primaryUser;
      defaultText = lib.literalExpression "config.system.primaryUser";
      description = "User the server runs as.";
    };

    dataDir = mkOption {
      type = types.str;
      default = "${home}/.local/share/cliproxyapi";
      defaultText = lib.literalExpression ''"/Users/''${user}/.local/share/cliproxyapi"'';
      description = "Directory with the OAuth logins (oauth.auth-dir).";
    };

    stateDir = mkOption {
      type = types.str;
      default = "${home}/.local/state/cliproxyapi";
      defaultText = lib.literalExpression ''"/Users/''${user}/.local/state/cliproxyapi"'';
      description = "Directory with the generated config.yaml and the logs.";
    };

    apiKeyFile = mkOption {
      type = types.str;
      example = "/Users/florian/.config/cliproxyapi/api-key";
      description = ''
        File with the key clients authenticate with (access.api-keys). It is
        read when the server starts, which refuses to run without it.
      '';
    };

    managementKeyFile = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "/Users/florian/.config/cliproxyapi/management-key";
      description = ''
        File with the key of the management api and its web panel
        (http://127.0.0.1:8317/management.html), read when the server starts.
        Without it both are disabled.
      '';
    };

    settings = mkOption {
      type = types.submodule {
        freeformType = format.type;
        options.server = {
          host = mkOption {
            type = types.str;
            default = "127.0.0.1";
            example = "";
            description = "Address the server listens on, empty for all interfaces.";
          };
          port = mkOption {
            type = types.port;
            default = 8317;
            description = "Port the server listens on.";
          };
        };
      };
      default = { };
      description = ''
        Configuration, see
        <https://github.com/router-for-me/CLIProxyAPI/blob/main/config.example.yaml>.
        The server may rewrite its config, so it is regenerated from this at
        every start and changes made through the management api are lost.
      '';
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ package ];

    system.activationScripts.postActivation.text = ''
      install -d -o ${cfg.user} -m 0700 ${lib.escapeShellArg cfg.dataDir} ${lib.escapeShellArg cfg.stateDir}
    '';

    launchd.daemons.cliproxyapi = {
      script = ''
        set -eu
        for file in ${lib.escapeShellArgs keyFiles}; do
          if [ ! -s "$file" ]; then
            echo "$file is missing, refusing to start" >&2
            exit 1
          fi
        done

        umask 077
        ${lib.getExe pkgs.jq} ${lib.escapeShellArgs jqArgs} ${settings} > ${lib.escapeShellArg configFile}

        exec ${lib.getExe package}
      '';
      serviceConfig = {
        UserName = cfg.user;
        RunAtLoad = true;
        KeepAlive = true;
        WorkingDirectory = cfg.stateDir;
        EnvironmentVariables.HOME = home;
        StandardOutPath = "${cfg.stateDir}/cliproxyapi.log";
        StandardErrorPath = "${cfg.stateDir}/cliproxyapi.log";
      };
    };
  };
}
