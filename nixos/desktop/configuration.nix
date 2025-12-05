{ pkgs, lib, ... }:
{
  system.stateVersion = "23.11";

  imports = [ ./hardware.nix ];
  sops.defaultSopsFile = ./secrets.yaml;

  custom = {
    audio.enable = true;
    dynamic-brightness.enable = false;

    nvidia.enable = true;
    desktop.enable = true;
    backup.enable = false;
    vpn.enable = true;
  };

  #######################
  # Low-Level Stuff     #
  #######################

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

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

    interfaces = {
      enp14s0.useDHCP = true;
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

  #######################
  # Programs & Services #
  #######################

  hardware.bluetooth = {
    enable = true;
  };

  services = {
    avahi.enable = true;
    gnome.gnome-keyring.enable = true;

    ollama = {
      enable = true;
      acceleration = "cuda";
    };

    printing = {
      # disabled due to security issue: https://dev.to/snyk/zero-day-rce-vulnerability-found-in-cups-common-unix-printing-system-flj
      enable = false;
      drivers = [ pkgs.splix ];
    };
  };

  programs = {
    _1password.enable = true;
    _1password-gui.enable = true;

    virt-manager.enable = true;

    steam = {
      enable = true;
      gamescopeSession.enable = true;
    };
  };

  # custom 1password browser integration
  environment.etc."1password/custom_allowed_browsers" = {
    mode = "0755";
    text = ''
      .zen-wrapped
    '';
  };

  environment.systemPackages = [
    pkgs.home-manager

    # TODO: move to home-manager config
    pkgs.docker-compose
  ];

  virtualisation = {
    docker.enable = true;

    libvirtd = {
      enable = true;
      qemu = {
        package = pkgs.qemu_kvm;
        runAsRoot = true;

        swtpm.enable = true;

        ovmf = {
          enable = true;
          packages = [
            (pkgs.OVMF.override {
              secureBoot = true;
              tpmSupport = true;
            }).fd
          ];
        };
      };
    };
  };

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
    ];
    initialPassword = "changeme";

    shell = pkgs.zsh;
  };
}
