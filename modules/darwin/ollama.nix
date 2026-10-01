{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.ollama;
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;
in
{
  options.services.ollama = {
    enable = mkEnableOption "the ollama server as a launchd daemon";

    package = lib.mkPackageOption pkgs "ollama" { };

    user = mkOption {
      type = types.str;
      default = config.system.primaryUser;
      defaultText = lib.literalExpression "config.system.primaryUser";
      description = "User the server runs as; models are stored in its ~/.ollama.";
    };

    host = mkOption {
      type = types.str;
      default = "127.0.0.1:11434";
      description = "Address the server listens on (OLLAMA_HOST).";
    };

    models = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "qwen2.5:14b" ];
      description = "Models pulled after the server starts.";
    };

    environment = mkOption {
      type = types.attrsOf types.str;
      default = { };
      example = {
        OLLAMA_KEEP_ALIVE = "30m";
      };
      description = "Extra environment variables of the server.";
    };
  };

  config = mkIf cfg.enable (
    let
      home = "/Users/${cfg.user}";
      logDir = "${home}/Library/Logs/ollama";
      ollama = lib.getExe cfg.package;
    in
    {
      environment.systemPackages = [ cfg.package ];

      system.activationScripts.postActivation.text = ''
        install -d -o ${cfg.user} -m 0755 ${logDir}
      '';

      launchd.daemons.ollama.serviceConfig = {
        ProgramArguments = [
          ollama
          "serve"
        ];
        UserName = cfg.user;
        RunAtLoad = true;
        KeepAlive = true;
        ProcessType = "Interactive";
        EnvironmentVariables = {
          HOME = home;
          OLLAMA_HOST = cfg.host;
        }
        // cfg.environment;
        StandardOutPath = "${logDir}/ollama.log";
        StandardErrorPath = "${logDir}/ollama.log";
      };

      # Pulls the configured models once the server answers; runs at boot and
      # after every activation, and is a no-op for models already present.
      launchd.daemons.ollama-pull = mkIf (cfg.models != [ ]) {
        script = ''
          for _ in $(seq 60); do
            ${ollama} list >/dev/null 2>&1 && break
            sleep 2
          done
          ${lib.concatMapStringsSep "\n" (m: "${ollama} pull ${lib.escapeShellArg m}") cfg.models}
        '';
        environment = {
          HOME = home;
          OLLAMA_HOST = cfg.host;
        };
        serviceConfig = {
          UserName = cfg.user;
          RunAtLoad = true;
          StandardOutPath = "${logDir}/ollama-pull.log";
          StandardErrorPath = "${logDir}/ollama-pull.log";
        };
      };
    }
  );
}
