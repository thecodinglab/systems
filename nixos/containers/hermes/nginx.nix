{
  config,
  modulesPath,
  pkgs,
  lib,
  ...
}:
let
  cloudflare = pkgs.callPackage ./cloudflare.nix { };
in
{
  options.custom.nginx = {
    enable = lib.mkEnableOption "enable nginx configuration";

    # NOTE: taken from https://github.com/NixOS/nixpkgs/blob/650ff82ad0fcea51e3733acb8c0e876cef6c7ebe/nixos/modules/services/web-servers/nginx/default.nix#L1069C7-L1088C9
    vhosts = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule (
          import (modulesPath + "/services/web-servers/nginx/vhost-options.nix") { inherit config lib; }
        )
      );
      default = { };
      example = lib.literalExpression ''
        {
          "hydra.example.com" = {
            forceSSL = true;
            enableACME = true;
            locations."/" = {
              proxyPass = "http://localhost:3000";
            };
          };
        };
      '';
      description = "Declarative vhost config";
    };
  };

  config = lib.mkIf config.custom.nginx.enable {
    services.nginx = {
      enable = true;

      commonHttpConfig =
        let
          realIPsFromList = lib.strings.concatMapStringsSep "\n" (x: "set_real_ip_from  ${x};");
        in
        ''
          ${realIPsFromList cloudflare.ipv4Proxies}
          ${realIPsFromList cloudflare.ipv6Proxies}
          real_ip_header CF-Connecting-IP;

          geo $local_address {
            default 0;

            127.0.0.0/8     1;
            192.168.1.0/24  1;
            172.16.0.0/24   1;

            ::1             1;
          }
        '';

      virtualHosts = lib.mapAttrs (
        _: config:
        config
        // {
          onlySSL = true;

          enableACME = true;
          acmeRoot = null;

          # NOTE: ssl certificates need to be installed manually
          sslCertificate = "/etc/certs/cloudflare-origin-cert.pem";
          sslCertificateKey = "/etc/certs/cloudflare-origin-key.pem";

          # require client certificate (mtls)
          extraConfig =
            ''
              ssl_client_certificate ${cloudflare.originPullCA};
              ssl_verify_client optional;

              set $access $ssl_client_verify;

              if ($local_address) {
                set $access "SUCCESS";
              }
            ''
            + (config.extraConfig or "");

          locations = builtins.mapAttrs (
            _: location:
            location
            // {
              recommendedProxySettings = true;
              proxyWebsockets = true;

              extraConfig =
                ''
                  if ($access != 'SUCCESS') {
                    return 403;
                  }
                ''
                + (location.extraConfig or "");
            }
          ) (config.locations or [ ]);
        }
      ) config.custom.nginx.vhosts;
    };
  };
}
