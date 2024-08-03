{ outputs, pkgs, ... }:
{
  system.stateVersion = "23.11";

  imports = [ ./hardware.nix ];

  nixpkgs.overlays = [
    outputs.overlays.additions
    outputs.overlays.modifications
  ];

  custom = {
    audio.enable = true;
    dynamic-brightness.enable = true;

    nvidia.enable = true;
    desktop.enable = true;
    backup.enable = true;
    vpn.enable = true;

    unfree = [
      "1password"
      "1password-cli"

      "steam"
      "steam-original"
      "steam-run"
    ];
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

    firewall.allowedTCPPorts = [
      22 # ssh
      5201 # iperf
    ];
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
      enable = true;
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

        ovmf.enable = true;
        swtpm.enable = true;
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
    ];
    initialPassword = "changeme";

    shell = pkgs.zsh;
  };
}
