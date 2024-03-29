{
  # Hestia: goddess of the hearth, home and domesticity

  infrastructure = ({ lib, ... }: rec {
    resource = {
      incus_instance.hestia = {
        name = "hestia";
        image = "images:nixos/23.11";

        profiles = [
          "default"
          "nesting"
          "autostart"
        ];
      };

      cloudflare_record = {
        teslamate = lib.cloudflare.makeDNSRecord "teslamate";
        home-assistant = lib.cloudflare.makeDNSRecord "home-assistant";
      };

      cloudflare_access_application = {
        teslamate = lib.cloudflare.makeDefaultApplication "teslamate";
        home-assistant = lib.cloudflare.makeDefaultApplication "home-assistant";
      };

      cloudflare_access_policy = {
        teslamate-policy-home = lib.cloudflare.makeHomeBypassAccessPolicy {
          application_id = "\${cloudflare_access_application.teslamate.id}";
          precedence = "2";
        };
        teslamate-policy-github = lib.cloudflare.makeGithubAllowancePolicy {
          application_id = "\${cloudflare_access_application.teslamate.id}";
          precedence = "1";
        };

        home-assistant-policy-home = lib.cloudflare.makeHomeBypassAccessPolicy {
          application_id = "\${cloudflare_access_application.home-assistant.id}";
          precedence = "2";
        };
        home-assistant-policy-github = lib.cloudflare.makeGithubAllowancePolicy {
          application_id = "\${cloudflare_access_application.home-assistant.id}";
          precedence = "1";
        };
      };
    };
  });

  system = ({ root, ... }: {
    networking = {
      hostName = "hestia";
      firewall = {
        allowedTCPPorts = [ ];
        allowedUDPPorts = [ ];
      };
    };


    virtualisation.oci-containers.containers = {
      teslamate-core = {
        hostname = "teslamate-core";
        image = "teslamate/teslamate:latest";
        autoStart = true;

        dependsOn = [
          "teslamate-postgres"
          "teslamate-mqtt"
          "teslamate-grafana"
        ];

        environment = {
          ENCRYPTION_KEY = builtins.readFile (root + "/secrets/teslamate-key.txt");
          DATABASE_USER = "teslamate";
          DATABASE_PASS = "teslamate";
          DATABASE_NAME = "teslamate";
          # FIXME: for some reason teslamate is unable to resolve the hostname
          #        (podman issue?)
          DATABASE_HOST = "10.88.0.4";
          MQTT_HOST = "10.88.0.3";
        };

        ports = [ "4000:4000" ];
      };

      teslamate-postgres = {
        hostname = "teslamate-postgres";
        image = "postgres:15";
        autoStart = true;

        environment = {
          POSTGRES_USER = "teslamate";
          POSTGRES_PASSWORD = "teslamate";
          POSTGRES_DB = "teslamate";
        };
        volumes = [
          "teslamate-postgres-data:/var/lib/postgresql/data"
        ];

        extraOptions = [
          "--ip=10.88.0.4"
        ];
      };

      teslamate-grafana = {
        hostname = "teslamate-grafana";
        image = "teslamate/grafana:latest";
        autoStart = true;

        dependsOn = [ "teslamate-postgres" ];

        environment = {
          DATABASE_USER = "teslamate";
          DATABASE_PASS = "teslamate";
          DATABASE_NAME = "teslamate";
          # FIXME: for some reason grafana is unable to resolve the hostname
          #        (podman issue?)
          DATABASE_HOST = "10.88.0.4";

          GF_AUTH_ANONYMOUS_ENABLED = "true";
          GF_SERVER_DOMAIN = "teslamate.thecodinglab.ch";
          GF_SERVER_ROOT_URL = "%(protocol)s://%(domain)s/grafana";
          GF_SERVER_SERVE_FROM_SUB_PATH = "true";
        };
        ports = [ "3000:3000" ];
        volumes = [
          "teslamate-grafana-data:/var/lib/grafana"
        ];
      };

      teslamate-mqtt = {
        hostname = "teslamate-mqtt";
        image = "eclipse-mosquitto:2";
        cmd = [ "mosquitto" "-c" "/mosquitto-no-auth.conf" ];
        autoStart = true;

        volumes = [
          "teslamate-misquitto-config:/mosquitto/config"
          "teslamate-misquitto-data:/mosquitto/data"
        ];

        extraOptions = [
          "--ip=10.88.0.3"
        ];
      };
    };

    services.home-assistant = {
      enable = true;
      openFirewall = true;

      extraComponents = [
        "hue"
      ];

      config = {
        default_config = { };
        http = {
          use_x_forwarded_for = true;
          trusted_proxies = "172.16.0.132";
        };
      };
    };

    # FIXME: see https://nixos.wiki/wiki/Home_Assistant
    nixpkgs.config.permittedInsecurePackages = [
      "openssl-1.1.1w"
    ];
  });
}
