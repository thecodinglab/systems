{ lib, pkgs, ... }:
{
  system.stateVersion = "23.11";

  imports =
    [
      # System
      ./hardware.nix
      ./security.nix

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
  # Networking          #
  #######################

  networking.hostName = "florian-nixos";

  networking.wireless =
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

  #######################
  # Services            #
  #######################

  services = {
    dbus.enable = true;
    avahi.enable = true;

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

    systemPackages = with pkgs; [
      brave
      firefox-devedition
      qutebrowser
    ];
  };
}

