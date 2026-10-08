{
  config,
  pkgs,
  keys,
  inputs,
  ...
}:
let
  xcloudCluster = inputs.xcloud.xcloudClusterConfigs.local;
  xcloudHost = xcloudCluster.hosts.desktop;

  xcloudProfile =
    name:
    { pkgs, ... }@args:
    import "${inputs.xcloud.outPath}/nix/profiles/${name}.nix" (
      args
      // {
        self = inputs.xcloud;
        cluster = xcloudCluster;
        host = xcloudHost;
      }
    );
in
{
  system.stateVersion = "23.11";

  imports = [
    ./hardware.nix
    ./storage.nix
    ./input/wooting.nix
    ./input/zsa.nix
  ]
  ++ map xcloudProfile ([ "base" ] ++ xcloudHost.roles);

  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets.wifi_home_psk = { };
    templates.wifi-secrets = {
      # wpa_supplicant runs as its own unprivileged user
      owner = "wpa_supplicant";
      content = ''
        home_psk=${config.sops.placeholder.wifi_home_psk}
      '';
    };
  };

  custom = {
    audio.enable = true;
    dynamic-brightness.enable = false;

    nvidia.enable = true;
    gaming.enable = true;
    desktop.enable = true;
    backup.enable = false;
    vpn.enable = true;
  };

  #######################
  # Low-Level Stuff     #
  #######################

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  # the menu wait was almost all of the 5s loader phase; 1s still leaves time to
  # pick an older generation
  boot.loader.timeout = 1;

  console = {
    font = "Lat2-Terminus16";
    useXkbConfig = true;
  };

  security.pam.loginLimits = [
    {
      domain = "*";
      type = "soft";
      item = "nofile";
      value = "unlimited";
    }
  ];

  networking = {
    useDHCP = false;
    hostName = "florian-nixos";

    interfaces.enp13s0 = {
      useDHCP = true;
      mtu = 9000;
      wakeOnLan.enable = true;
    };

    interfaces.wlp11s0.useDHCP = true;

    wireless = {
      enable = true;
      interfaces = [ "wlp11s0" ];
      secretsFile = config.sops.templates.wifi-secrets.path;
      networks."☕".pskRaw = "ext:home_psk";
    };

    firewall = {
      allowedTCPPorts = [
        22 # ssh
        3000 # dev
        5201 # iperf
        8080 # dev
      ];

      trustedInterfaces = [ "virbr0" ];
    };
  };

  # Both NICs are on the same LAN and DHCP gives both default routes the same
  # metric, so flows randomly go over the slower Wi-Fi. Prefer the wire and
  # keep Wi-Fi as fallback. Merges into the units from networking.interfaces.
  systemd.network.networks = {
    "40-enp13s0" = {
      dhcpV4Config.RouteMetric = 100;
      ipv6AcceptRAConfig.RouteMetric = 100;
    };
    "40-wlp11s0" = {
      dhcpV4Config.RouteMetric = 600;
      ipv6AcceptRAConfig.RouteMetric = 600;
    };
  };

  #######################
  # Programs & Services #
  #######################

  hardware.bluetooth = {
    enable = true;
  };

  services = {
    avahi.enable = true;
    gnome.gnome-keyring.enable = true;

    printing = {
      # disabled due to security issue: https://dev.to/snyk/zero-day-rce-vulnerability-found-in-cups-common-unix-printing-system-flj
      enable = false;
      drivers = [ pkgs.splix ];
    };
  };

  programs = {
    _1password.enable = true;
    _1password-gui.enable = true;

    tether = {
      enable = true;
      wifi = {
        enable = true;
        openFirewall = true;
      };
      bluetooth = {
        enable = true;
        adapters = [ "hci0" ];
      };
    };

    virt-manager.enable = true;
  };

  # custom 1password browser integration
  environment.etc."1password/custom_allowed_browsers" = {
    mode = "0755";
    text = ''
      helium
    '';
  };

  environment.systemPackages = [
    # TODO: move to home-manager config
    pkgs.docker-compose
  ];

  virtualisation = {
    docker = {
      enable = true;
      # docker.socket stays, dockerd starts on first use instead of at boot
      enableOnBoot = false;
    };
    vswitch.enable = true;
  };

  # allow running non nix-packaged applications
  programs.nix-ld.enable = true;

  security.sudo.wheelNeedsPassword = false;

  #######################
  # Users               #
  #######################

  users.users.florian = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "docker"
      "libvirtd"
      "plugdev"

      "xcloud"
    ];
    initialPassword = "changeme";

    shell = pkgs.zsh;

    openssh.authorizedKeys.keys = [ keys.personal ];
  };

  home-manager.users.florian = ./home.nix;
}
