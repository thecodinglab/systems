{ outputs, pkgs, ... }:
{
  nixpkgs.overlays = [
    outputs.overlays.additions
    outputs.overlays.modifications
  ];

  custom.unfree = [
    "obsidian"
    "spotify"
    "1password"
  ];

  programs.gnupg.agent.enable = true;

  networking = {
    computerName = "Florian’s MacBook Pro";
    hostName = "Florians-MacBook-Pro";
    localHostName = "Florians-MacBook-Pro";
  };

  environment.systemPackages = [ pkgs.home-manager ];

  users.users.florian = {
    name = "florian";
    home = "/Users/florian/";
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

      expose-group-by-app = true;
      mru-spaces = false;

      persistent-apps = [
        "/Applications/Arc.app" # TODO: move into nix-darwin config
        "/Applications/Safari.app"
        "/System/Applications/Mail.app"
        "/Applications/Slack.app" # TODO: move into nix-darwin config
        "/System/Applications/Calendar.app"

        "${pkgs.kitty}/Applications/kitty.app"
        "${pkgs.obsidian}/Applications/Obsidian.app"

        "${pkgs.spotify}/Applications/Spotify.app"
        "${pkgs._1password-gui}/Applications/1Password.app"
        "/System/Applications/System Settings.app"
        "/System/Applications/iPhone Mirroring.app"
      ];
    };

    CustomUserPreferences."com.apple.dock".persistent-others = [
      {
        tile-data = {
          arrangement = 1; # 1 = name, 2 = date-added, 3 = date-modified, 4 = date-created, 5 = kind
          displayas = 1; # 0 = stack, 1 = folder
          showas = 2; # 0 = automatic, 1 = fan, 2 = grid, 3 = list

          file-data = {
            _CFURLString = "file:///Users/florian/Documents/";
            _CFURLStringType = 15;
          };
        };
        tile-type = "directory-tile";
      }
      {
        tile-data = {
          arrangement = 2; # 1 = name, 2 = date-added, 3 = date-modified, 4 = date-created, 5 = kind
          displayas = 1; # 0 = stack, 1 = folder
          showas = 1; # 0 = automatic, 1 = fan, 2 = grid, 3 = list

          file-data = {
            _CFURLString = "file:///Users/florian/Downloads/";
            _CFURLStringType = 15;
          };
        };
        tile-type = "directory-tile";
      }
    ];

    menuExtraClock = {
      ShowDate = 0;
      ShowDayOfMonth = true;
      ShowDayOfWeek = true;

      Show24Hour = true;
      ShowSeconds = true;

      IsAnalog = false;
      ShowAMPM = false;
    };
  };

  system.stateVersion = 5;
}
