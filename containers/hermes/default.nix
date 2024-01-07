args@{ pkgs, lib, ... }:
let
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

  vhosts = lib.mapAttrs (_: mergeBaseConfig) (baseVhosts // (args.vhosts or { }));
in
{
  services.nginx = {
    enable = true;

    commonHttpConfig =
      let
        realIPsFromList = lib.strings.concatMapStringsSep "\n" (x: "set_real_ip_from  ${x};");
        fileToList = (x: lib.strings.splitString "\n" (builtins.readFile x));

        cfipv4 = fileToList (pkgs.fetchurl {
          url = "https://www.cloudflare.com/ips-v4";
          sha256 = "0ywy9sg7spafi3gm9q5wb59lbiq0swvf0q3iazl0maq1pj1nsb7h";
        });

        cfipv6 = fileToList (pkgs.fetchurl {
          url = "https://www.cloudflare.com/ips-v6";
          sha256 = "1ad09hijignj6zlqvdjxv7rjj8567z357zfavv201b9vx3ikk7cy";
        });
      in
      ''
        ${realIPsFromList cfipv4}
        ${realIPsFromList cfipv6}
        real_ip_header CF-Connecting-IP;
      '';


    virtualHosts = vhosts;
  };

  virtualisation.oci-containers.containers = {
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
}
