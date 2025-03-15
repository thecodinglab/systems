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

  programs.zsh.enable = true;

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
      GloballyEnabled = true;
      # disable hiding of all applications when clicking on wallpaper
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

  system.keyboard = {
    enableKeyMapping = true;
    remapCapsLockToEscape = true;
  };
}
