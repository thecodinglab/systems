{ modulesPath, ... }:
{
  system.stateVersion = "23.11";

  imports = [ (modulesPath + "/virtualisation/lxc-container.nix") ];

  nixpkgs.hostPlatform = "x86_64-linux";

  custom.isContainer = true;

  networking = {
    hostName = "hestia";
    firewall.allowedTCPPorts = [
      3000
      4000
      8123
    ];
  };

  systemd.timers.podman-auto-update = {
    timerConfig = {
      Unit = "podman-auto-update.service";
      OnCalendar = "Mon 02:00";
      Persistent = true;
    };
    wantedBy = [ "timers.target" ];
  };

  virtualisation.oci-containers.containers = {
    teslamate-core = {
      hostname = "teslamate-core";
      image = "docker.io/teslamate/teslamate:latest";
      autoStart = true;

      labels = {
        "io.containers.autoupdate" = "registry";
      };

      dependsOn = [
        "teslamate-postgres"
        "teslamate-mqtt"
        "teslamate-grafana"
      ];

      environment = {
        # FIXME: the current encryption key contains a '\n' character, which is
        # currently not supported by env-files in podman (see
        # https://github.com/containers/podman/issues/18724), also it seems to
        # be currently not possible to rotate teslamate keys and thus, this
        # cannot be moved to sops right now.
        ENCRYPTION_KEY = builtins.readFile ../../../secrets/teslamate-key.txt;
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
      image = "docker.io/postgres:15";
      autoStart = true;

      labels = {
        "io.containers.autoupdate" = "registry";
      };

      environment = {
        POSTGRES_USER = "teslamate";
        POSTGRES_PASSWORD = "teslamate";
        POSTGRES_DB = "teslamate";
      };
      volumes = [ "teslamate-postgres-data:/var/lib/postgresql/data" ];

      extraOptions = [ "--ip=10.88.0.4" ];
    };

    teslamate-grafana = {
      hostname = "teslamate-grafana";
      image = "docker.io/teslamate/grafana:latest";
      autoStart = true;

      dependsOn = [ "teslamate-postgres" ];

      labels = {
        "io.containers.autoupdate" = "registry";
      };

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
      volumes = [ "teslamate-grafana-data:/var/lib/grafana" ];
    };

    teslamate-mqtt = {
      hostname = "teslamate-mqtt";
      image = "docker.io/eclipse-mosquitto:2";
      cmd = [
        "mosquitto"
        "-c"
        "/mosquitto-no-auth.conf"
      ];
      autoStart = true;

      labels = {
        "io.containers.autoupdate" = "registry";
      };

      volumes = [
        "teslamate-misquitto-config:/mosquitto/config"
        "teslamate-misquitto-data:/mosquitto/data"
      ];

      extraOptions = [ "--ip=10.88.0.3" ];
    };
  };

  services.home-assistant = {
    enable = true;

    extraComponents = [ "hue" ];

    config = {
      default_config = { };
      http = {
        use_x_forwarded_for = true;
        trusted_proxies = "172.16.0.132";
      };
    };
  };
}
