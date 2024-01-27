{ lib, pkgs, root, ... }:
{
  system.stateVersion = "23.11";

  imports =
    [
      # System
      ./hardware.nix
      ./security.nix

      (root + "/modules/nixos/base")
      (root + "/modules/nixos/nvidia")

      (root + "/modules/nixos/audio")
      (root + "/modules/nixos/dynamic-brightness")
      (root + "/modules/nixos/podman")
      (root + "/modules/nixos/ssh")

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
      pskPath = root + "/secrets/wireless_psk.txt";
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

  services.xserver = {
    enable = true;
    autorun = true;

    # Keyboard Layout
    xkb = {
      layout = "us";
      options = "compose:rwin";
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
    windowManager.i3.enable = true;

    desktopManager = {
      xterm.enable = false;

      wallpaper = {
        combineScreens = false;
        mode = "fill";
      };
    };

    displayManager = {
      defaultSession = "none+i3";
    };

    # Other
    excludePackages = with pkgs; [ xterm ];
  };

  # clipboard manager
  services.clipcat.enable = true;

  #######################
  # Services            #
  #######################

  services.dbus.enable = true;
  services.printing.enable = true;

  #######################
  # Applications        #
  #######################

  programs.zsh.enable = true;

  environment = {
    shells = [ pkgs.zsh ];

    variables = {
      TERMINAL = "${pkgs.alacritty}/bin/alacritty";
    };

    systemPackages = with pkgs; [
      firefox
    ];
  };
}

