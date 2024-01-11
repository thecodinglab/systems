{
  # Hermes: god of boundaries, travel, trade, communication

  infrastructure = ({ lib, ... }: {
    resource.incus_instance.hermes = {
      name = "hermes";
      image = "images:nixos/23.11";

      profiles = [
        "default"
        "nesting"
        "autostart"
      ];
    };

    resource.cloudflare_record.hermes = lib.makeCloudflareDNSRecord "hermes";
  });

  system = ({ pkgs, lib, root, hermes, ... }:
    let
      cloudflareOriginPullCA = builtins.fetchurl {
        url = "https://developers.cloudflare.com/ssl/static/authenticated_origin_pull_ca.pem";
        sha256 = "0hxqszqfzsbmgksfm6k0gp0hsx9k1gqx24gakxqv0391wl6fsky1";
      };

      mergeBaseConfig = (config: config // {
        onlySSL = true;

        enableACME = true;
        acmeRoot = null;

        # ssl certificates need to be installed manually
        sslCertificate = "/etc/certs/cloudflare-origin-cert.pem";
        sslCertificateKey = "/etc/certs/cloudflare-origin-key.pem";

        # require client certificate
        extraConfig = ''
          ssl_client_certificate ${cloudflareOriginPullCA};
          ssl_verify_client optional;

          set $access $ssl_client_verify;

          if ($local_address) {
            set $access "SUCCESS";
          }
        '' + (config.extraConfig or "");

        locations = builtins.mapAttrs
          (_: location: location // {
            extraConfig = ''
              if ($access != 'SUCCESS') {
                return 403;
              }
            '' + (location.extraConfig or "");
          })
          (config.locations or [ ]);
      });

      baseVHosts = {
        "hermes.thecodinglab.ch" = {
          locations."/" = {
            proxyPass = "http://localhost:7575/";
            recommendedProxySettings = true;
          };
        };

      } // import (root + "/secrets/private-hosts.nix") // (hermes.vhosts or { });

      vhosts = lib.mapAttrs (_: mergeBaseConfig) baseVHosts;
    in
    {
      networking = {
        hostName = "hermes";
        firewall.allowedTCPPorts = [ 443 ];
        firewall.allowedUDPPorts = [ 53 ];
      };

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

            geo $local_address {
              default 0;
              192.168.1.0/24 1;
            }
          '';


        virtualHosts = vhosts;
      };

      services.bind = {
        enable = true;

        forwarders = [
          "1.1.1.1"
          "8.8.8.8"
        ];

        extraOptions = ''
          allow-query-cache { any; };

          response-policy { zone "rpz"; };
        '';

        zones.rpz = {
          master = true;
          file = ./config/zone.dns;
        };
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

      security.acme = {
        acceptTerms = true;
        defaults = {
          email = "nairolf.retlaw@gmail.com";
          dnsProvider = "cloudflare";
          credentialsFile = pkgs.writeText "cloudflare-credentials"
            (builtins.readFile (root + "/secrets/acme-cloudflare.env"));
        };
      };
    });
}
