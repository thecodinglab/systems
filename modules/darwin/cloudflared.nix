# cloudflared as a launchd daemon running one locally-managed tunnel
# (counterpart of the nixos module services.cloudflared, which is systemd
# only). The tunnel is created by hand, see docs/macmini-cloudflare-tunnel.md;
# its credentials are only read at runtime, so they never end up in the store.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.cloudflared;
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;

  format = pkgs.formats.json { };
  home = "/Users/${cfg.user}";
  logDir = "${home}/.local/state/cloudflared";

  # yaml is a superset of json; only the path of the credentials is in here
  configFile = format.generate "cloudflared.json" {
    credentials-file = cfg.credentialsFile;
    metrics = "127.0.0.1:20241";
    ingress =
      lib.mapAttrsToList (
        hostname: rule:
        {
          inherit hostname;
          inherit (rule) service;
        }
        // lib.optionalAttrs (rule.originRequest != { }) { inherit (rule) originRequest; }
      ) cfg.ingress
      ++ [ { service = "http_status:404"; } ];
  };

  uuid = "^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$";
in
{
  options.services.cloudflared = {
    enable = mkEnableOption "a locally-managed Cloudflare tunnel as a launchd daemon";

    package = lib.mkPackageOption pkgs "cloudflared" { };

    user = mkOption {
      type = types.str;
      default = config.system.primaryUser;
      defaultText = lib.literalExpression "config.system.primaryUser";
      description = "User the tunnel runs as; it has to be able to read the credentials.";
    };

    credentialsFile = mkOption {
      type = types.strMatching "/.*";
      example = "/Users/florian/.config/cloudflared/macmini.json";
      description = ''
        Credentials of the tunnel (`cloudflared tunnel create --cred-file`), read
        when the daemon starts, which refuses to run without it. The tunnel id
        is taken from it, so it alone decides which tunnel is run.
      '';
    };

    ingress = mkOption {
      type = types.attrsOf (
        types.submodule {
          options = {
            service = mkOption {
              type = types.str;
              example = "http://127.0.0.1:8080";
              description = "Origin the requests for the hostname are passed to.";
            };
            originRequest = mkOption {
              type = types.attrsOf format.type;
              default = { };
              description = ''
                Origin settings of the rule, see
                <https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/configure-tunnels/origin-configuration/>.
              '';
            };
          };
        }
      );
      default = { };
      example = lib.literalExpression ''
        {
          "kakeibo.ch".service = "http://127.0.0.1:8080";
        }
      '';
      description = "Ingress rules by hostname; everything else gets a 404.";
    };
  };

  config = mkIf cfg.enable {
    system.activationScripts.postActivation.text = ''
      install -d -o ${cfg.user} -m 0700 ${lib.escapeShellArg logDir}
    '';

    launchd.daemons.cloudflared = {
      script = ''
        set -eu
        credentials=${lib.escapeShellArg cfg.credentialsFile}
        if [ ! -s "$credentials" ]; then
          echo "$credentials is missing, refusing to start" >&2
          exit 1
        fi

        # errors of jq are dropped, they could quote the secret
        if ! tunnel=$(${lib.getExe pkgs.jq} -er '.TunnelID | strings | select(test("${uuid}"))' "$credentials" 2>/dev/null); then
          echo "$credentials has no valid TunnelID, refusing to start" >&2
          exit 1
        fi

        exec ${lib.getExe cfg.package} tunnel --no-autoupdate --config ${configFile} run "$tunnel"
      '';
      serviceConfig = {
        UserName = cfg.user;
        RunAtLoad = true;
        KeepAlive = true;
        # missing credentials or no network: don't restart every 10s
        ThrottleInterval = 30;
        WorkingDirectory = logDir;
        EnvironmentVariables.HOME = home;
        StandardOutPath = "${logDir}/cloudflared.log";
        StandardErrorPath = "${logDir}/cloudflared.log";
      };
    };
  };
}
