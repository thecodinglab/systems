args@{ lib, ... }:
let
  config = args.hermes or { };

  mergeBaseConfig = (config: {
    onlySSL = true;
    enableACME = false;

    # ssl certificates need to be installed manually
    sslCertificate = "/etc/certs/cloudflare-origin-cert.pem";
    sslCertificateKey = "/etc/certs/cloudflare-origin-key.pem";
    sslTrustedCertificate = "/etc/certs/cloudflare-origin-pull-ca-cert.pem";
  } // config);

  baseVhosts = {
    default = {
      default = true;
      locations."/".return = "404";
    };

    "hermes.thecodinglab.ch" = {
      locations."/" = {
        proxyPass = "http://localhost:7575/";
        recommendedProxySettings = true;
      };
    };
  };

  vhosts = lib.mapAttrs (_: mergeBaseConfig) (baseVhosts // (config.vhosts or { }));
in
{
  services.nginx = {
    enable = true;

    virtualHosts = vhosts;
  };

  virtualisation.oci-containers = {
    backend = "docker";

    containers = {
      homarr = {
        autoStart = true;
        image = "ghcr.io/ajnart/homarr:latest";
        ports = [
          "127.0.0.1:7575:7575"
        ];
        volumes = [
          "homarr-config:/app/data/configs"
          "homarr-icons:/app/public/icons"
          "homarr-data:/data"
        ];
      };
    };
  };
}
