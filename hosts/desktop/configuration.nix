{ lib, pkgs, ... }:
{
  system.stateVersion = "23.11";

  imports =
    [
      # System
      ./hardware.nix
      ./security.nix

      ../../modules/nixos/base
      ../../modules/nixos/nvidia

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
  # Desktop             #
  #######################

  services.autorandr.enable = true;

  services.displayManager.defaultSession = "none+bspwm";

  services.xserver = {
    enable = true;
    autorun = true;

    # Keyboard Layout
    xkb = {
      layout = "us";
      options = "compose:rwin";
    };

    # Trackpad
    libinput.touchpad = {
      accelSpeed = "0.5";
      naturalScrolling = true;
    };

    # Monitor Arrangement (from nvidia-settings)
    screenSection = ''
      Option "metamodes" "DP-4: nvidia-auto-select +6000+0, DP-0.8: nvidia-auto-select +0+0, DP-2: nvidia-auto-select +2560+0"
    '';

    xrandrHeads = [
      { output = "DP-0.8"; primary = false; }
      { output = "DP-2"; primary = true; }
      { output = "DP-4"; primary = false; }
    ];

    videoDrivers = [ "nvidia" ];

    # Desktop Environment
    windowManager.bspwm.enable = true;

    desktopManager = {
      xterm.enable = false;

      wallpaper = {
        combineScreens = false;
        mode = "fill";
      };
    };

    # Other
    excludePackages = with pkgs; [ xterm ];
  };

  # clipboard manager
  services.clipcat.enable = true;

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
    ];
  };
}

