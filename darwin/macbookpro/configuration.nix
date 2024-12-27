{
  outputs,
  pkgs,
  ...
}:
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

  system.defaults.dock.persistent-apps = [
    "/System/Cryptexes/App/System/Applications/Safari.app"
    "/Applications/Firefox Developer Edition.app"
    "/System/Applications/Mail.app"
    "/Applications/Slack.app" # managed through homebrew
    "/System/Applications/Calendar.app"

    "${pkgs.kitty}/Applications/kitty.app"
    "${pkgs.obsidian}/Applications/Obsidian.app"
    "/Applications/TablePlus.app" # managed through homebrew
    "/Applications/Figma.app" # managed through homebrew
    "/Applications/Linear.app" # managed through homebrew

    "/Applications/Spotify.app" # managed through homebrew
    "/Applications/1Password.app" # managed through homebrew
    "/System/Applications/System Settings.app"
    "/System/Applications/iPhone Mirroring.app"
  ];

  system.defaults.CustomUserPreferences."com.apple.dock".persistent-others = [
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

  homebrew = {
    enable = true;
    casks = [
      "spotify"
      "1password"
      "raycast"
      "protonmail-bridge"
      "google-drive"

      "figma"
      "linear-linear"
      "orbstack"
      "tableplus"

      "google-chrome"
      "firefox@developer-edition"
    ];
    masApps = {
      "Pages" = 409201541;
      "Numbers" = 409203825;
      "1Password for Safari" = 1569813296;
      "Slack" = 803453959;
      "Lightroom" = 1451544217;
      "LanguageTool" = 1534275760;
    };
    onActivation.cleanup = "zap";
  };

  system.stateVersion = 5;
}
