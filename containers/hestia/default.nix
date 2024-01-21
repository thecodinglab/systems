{
  # Hestia: goddess of the hearth, home and domesticity

  infrastructure = ({ lib, ... }: rec {
    resource.incus_instance.hestia = {
      name = "hestia";
      image = "images:nixos/23.11";

      profiles = [
        "default"
        "nesting"
      ];
    };

    # TODO:
    # resource.cloudflare_record = {
    #   media = lib.makeCloudflareDNSRecord "media";
    #   requests = lib.makeCloudflareDNSRecord "requests";
    #   media-tools = lib.makeCloudflareDNSRecord "media-tools";
    # };
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
          MQTT_HOST = "teslamate-mqtt";
        };

        ports = [
          "4000:4000"
        ];
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
        };
        ports = [
          "3000:3000"
        ];
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
      };
    };

    # FIXME: see https://nixos.wiki/wiki/Home_Assistant
    nixpkgs.config.permittedInsecurePackages = [
      "openssl-1.1.1w"
    ];
  });
}
