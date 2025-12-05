{
  config,
  pkgs,
  ...
}:
{
  system.stateVersion = "23.11";

  imports = [
    # System
    ./hardware.nix

    ./ups.nix
    ./incus.nix

    # User
    ./users/nix/configuration.nix
  ];

  #######################
  # General             #
  #######################

  time.timeZone = "Europe/Zurich";

  i18n = {
    supportedLocales = [ "en_US.UTF-8/UTF-8" ];
    defaultLocale = "en_US.UTF-8";
  };

  console.font = "Lat2-Terminus16";

  security.sudo = {
    wheelNeedsPassword = false;
    execWheelOnly = true;
  };

  #######################
  # Boot                #
  #######################

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  #######################
  # Networking          #
  #######################

  networking = {
    useNetworkd = false;
    useDHCP = false;

    hostName = "server";

    interfaces.eno1np0 = {
      useDHCP = true;
    };

    bridges.br0 = {
      interfaces = [ "eno2np1" ];
    };

    firewall = {
      allowedTCPPorts = [
        22 # ssh
        8443 # incus api
        3000 # grafana
        5201 # iperf
      ];

      trustedInterfaces = [
        "eno2np1"
        "br0"
      ];
    };
  };

  #######################
  # Applications        #
  #######################

  environment.systemPackages = [
    pkgs.bridge-utils
    pkgs.tcpdump
    pkgs.iperf
    pkgs.neovim-minimal
  ];

  #######################
  # Monitoring          #
  #######################

  services = {
    grafana = {
      enable = true;
      settings = {
        server = {
          http_addr = "0.0.0.0";
          http_port = 3000;
        };
      };
    };

    prometheus = {
      enable = true;

      globalConfig.scrape_interval = "10s";

      scrapeConfigs = [
        {
          job_name = "node";
          static_configs = [
            { targets = [ "localhost:${toString config.services.prometheus.exporters.node.port}" ]; }
          ];
        }
        {
          job_name = "apcupsd";
          static_configs = [
            { targets = [ "localhost:${toString config.services.prometheus.exporters.apcupsd.port}" ]; }
          ];
        }
      ];

      exporters = {
        node = {
          enable = true;
          enabledCollectors = [
            "processes"
            "systemd"
          ];
        };
        apcupsd.enable = true;
      };
    };
  };
}
