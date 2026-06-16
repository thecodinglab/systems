{ pkgs, lib, ... }:
{
  nix = {
    enable = true;

    settings = {
      auto-optimise-store = false;
    };

    extraOptions = ''
      experimental-features = nix-command flakes
    '';

    gc = {
      automatic = true;
      interval = [
        {
          Hour = 9;
          Minute = 0;
        }
      ];
    };
  };

  documentation = {
    enable = lib.mkDefault true;
    man.enable = lib.mkDefault true;
  };

  environment = {
    variables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
    };

    shellAliases = {
      vi = "nvim";
      vim = "nvim";
      view = "nvim -R";
      vimdiff = "nvim -d";
      ex = "nvim -e";
    };

    shells = [ pkgs.zsh ];

    systemPackages = [
      pkgs.coreutils
      pkgs.neovim-dev
    ];

    pathsToLink = [
      # link zsh completions for system packages
      "/share/zsh"
    ];
  };

  programs.zsh = {
    enable = true;
    enableGlobalCompInit = false;
  };

  system.defaults = {
    NSGlobalDomain = {
      AppleInterfaceStyleSwitchesAutomatically = true;
      NSAutomaticCapitalizationEnabled = false;
      KeyRepeat = 2;
    };

    loginwindow.GuestEnabled = false;

    finder = {
      AppleShowAllExtensions = true;
      FXPreferredViewStyle = "Nlsv";
      FXDefaultSearchScope = "SCcf";
      NewWindowTarget = "Home";
      ShowPathbar = true;
    };

    WindowManager = {
      # enable stage manager
      GloballyEnabled = false;

      # always hide desktop items
      StandardHideDesktopIcons = true;
      EnableStandardClickToShowDesktop = false;

      AppWindowGroupingBehavior = true;
    };

    dock = {
      orientation = "bottom";
      show-recents = false;

      autohide = true;
      autohide-delay = 0.2;

      tilesize = 48;
      magnification = true;
      largesize = 64;

      expose-group-apps = true;
      mru-spaces = false;
    };

    menuExtraClock = {
      ShowDate = 0;
      ShowDayOfMonth = true;
      ShowDayOfWeek = true;

      Show24Hour = true;
      ShowSeconds = true;

      IsAnalog = false;
      ShowAMPM = false;
    };

    trackpad.Clicking = true;
  };

  # disable the stupid "allow app to access the local network" dialog
  system.defaults.CustomSystemPreferences."com.apple.network.local-network" =
    let
      addrs = [
        "10.0.0.0/8"
        "172.16.0.0/12"
        "192.168.0.0/16"
      ];
    in
    {
      AllowedEthernetLocalNetworkAddresses = addrs;
      AllowedWiFiLocalNetworkAddresses = addrs;
    };

  system.keyboard = {
    enableKeyMapping = true;
    remapCapsLockToEscape = true;
  };
}
