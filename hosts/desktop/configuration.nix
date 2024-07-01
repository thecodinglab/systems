{ lib, pkgs, ... }:
{
  system.stateVersion = "23.11";

  imports =
    [
      # System
      ./hardware.nix

      ../../modules/nixos/base
      ../../modules/nixos/hyprland
      ../../modules/nixos/nvidia
      ../../modules/nixos/virt

      ../../modules/nixos/1password
      ../../modules/nixos/audio
      ../../modules/nixos/docker
      ../../modules/nixos/dynamic-brightness
      ../../modules/nixos/podman
      ../../modules/nixos/ssh
      ../../modules/nixos/steam

      # User
      ./users/florian
    ];

  #######################
  # General             #
  #######################

  time = {
    timeZone = "Europe/Zurich";
    # use localtime to allow dual booting with windows
    hardwareClockInLocalTime = true;
  };

  i18n = {
    supportedLocales = [ "en_US.UTF-8/UTF-8" "de_CH.UTF-8/UTF-8" ];
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_NUMERIC = "de_CH.UTF-8";
      LC_TIME = "de_CH.UTF-8";
      LC_MONETARY = "de_CH.UTF-8";
      LC_MEASUREMENT = "de_CH.UTF-8";
    };
  };

  console = {
    font = "Lat2-Terminus16";
    useXkbConfig = true;
  };

  documentation = {
    enable = true;
    dev.enable = true;
    man.enable = true;
  };

  #######################
  # Boot                #
  #######################

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  #######################
  # Limits              #
  #######################

  security.pam.loginLimits = [
    { domain = "*"; type = "soft"; item = "nofile"; value = "unlimited"; }
  ];

  #######################
  # Networking          #
  #######################

  networking = {
    useDHCP = false;
    hostName = "florian-nixos";

    interfaces = {
      enp14s0.useDHCP = true;
      wlp15s0.useDHCP = true;
    };

    wireless =
      let
        pskPath = ../../secrets/wireless_psk.txt;
        pskExists = builtins.pathExists pskPath;
      in
      {
        enable = pskExists;
        networks = lib.mkIf pskExists {
          Privat.pskRaw = builtins.readFile pskPath;
        };
      };

    nftables.enable = true;

    firewall = {
      enable = true;
      allowedTCPPorts = [
        22 # ssh
        5201 # iperf
      ];
      allowedUDPPorts = [ ];
    };
  };


  #######################
  # Services            #
  #######################

  services = {
    dbus.enable = true;
    avahi.enable = true;
    gnome.gnome-keyring.enable = true;

    printing = {
      enable = true;
      drivers = [ pkgs.splix ];
    };
  };

  #######################
  # Applications        #
  #######################

  programs.zsh.enable = true;

  environment = {
    shells = [ pkgs.zsh ];
  };

  hardware.bluetooth = {
    enable = true;
  };

  #######################
  # Backup              #
  #######################

  services.snapper = {
    snapshotInterval = "hourly";
    cleanupInterval = "7d";

    snapshotRootOnBoot = true;
    persistentTimer = false;

    configs = {
      root = {
        SUBVOLUME = "/";
        TIMELINE_CREATE = true;
        TIMELINE_CLEANUP = true;
      };
    };
  };
}
