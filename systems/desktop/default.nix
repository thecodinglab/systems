{ config, pkgs, home-manager, root, ... }:
{
  system.stateVersion = "23.11";

  imports = 
    [ # System
      ./hardware.nix
      ./security.nix

      (root + "/modules/nixos/zsh")
      (root + "/modules/nixos/audio")
      (root + "/modules/nixos/podman")
      (root + "/modules/nixos/dynamic-brightness")

      # User
      (root + "/users/florian")
    ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  
  #######################
  # General             #
  #######################

  time = {
    timeZone = "Europe/Zurich";
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

  documentation.enable = true;
  documentation.dev.enable = true;

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
    in {
      enable = pskExists;
      networks = if pskExists then {
        Privat.pskRaw = builtins.readFile pskPath;
      } else {};
    };
  
  #######################
  # Environment         #
  #######################

  environment = {
    shells = [ pkgs.zsh ];
    shellAliases = {
      ls = "ls -l --color=auto --group-directories-first -I . -I ..";
    };

    variables = {
      TERMINAL = pkgs.alacritty;
      EDITOR = pkgs.neovim;
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

    # Monitor Arrangement
    screenSection = ''
      Option "metamodes" "DP-4: nvidia-auto-select +2560+0, DP-0: nvidia-auto-select +0+0, DP-2: nvidia-auto-select +6000+0"
    '';

    xrandrHeads = [
      "DP-0"
      "DP-2"
      { output = "DP-4"; primary = true; }
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
  
  #######################
  # Services            #
  #######################

  services.dbus.enable = true;
  services.printing.enable = true;
  
  #######################
  # Applications        #
  #######################

  environment.systemPackages = with pkgs; [
    # Mandatory System Management CLIs
    htop
    neovim

    # Desktop Applications
    firefox
  ];
}

