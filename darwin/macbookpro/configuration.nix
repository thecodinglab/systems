{ pkgs, ... }:
{
  programs.gnupg.agent.enable = true;

  networking = {
    computerName = "Florian’s MacBook Pro";
    hostName = "Florians-MacBook-Pro";
    localHostName = "Florians-MacBook-Pro";
  };

  environment.systemPackages = [
    pkgs.home-manager

    pkgs.ghostty-bin
    pkgs.obsidian
  ];

  system.primaryUser = "florian";
  users.users.florian = {
    name = "florian";
    home = "/Users/florian/";
  };

  security.sudo.extraConfig = ''
    %admin ALL=(ALL) NOPASSWD: ALL
  '';

  system.defaults.dock.persistent-apps = [
    "/System/Cryptexes/App/System/Applications/Safari.app"
    "/Applications/Helium.app" # managed through homebrew
    "/System/Applications/Mail.app"
    "/Applications/Slack.app" # managed through homebrew
    "/System/Applications/Calendar.app"

    "/Applications/Nix Apps/Ghostty.app" # managed through nix-darwin
    "/Applications/Nix Apps/Obsidian.app" # managed through nix-darwin
    "/Applications/Linear.app" # managed through homebrew

    "/Applications/Claude.app" # managed through homebrew
    "/Applications/ChatGPT.app" # managed through homebrew
    "/Applications/Codex.app" # managed through homebrew

    "/Applications/Spotify.app" # managed through homebrew
    "/Applications/1Password.app" # managed through homebrew
    "/System/Applications/System Settings.app"
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
      "1password-cli"

      "figma"
      "linear"
      "orbstack"

      "helium-browser"
      "google-chrome"
      "whatsapp"

      "claude"
      "chatgpt"
      "codex-app"
    ];
    masApps = {
      "Pages" = 409201541;
      "Numbers" = 409203825;
      "1Password for Safari" = 1569813296;
      "Slack" = 803453959;
      "LanguageTool" = 1534275760;
    };
    onActivation = {
      cleanup = "zap";
      upgrade = true;
    };
  };

  system.stateVersion = 5;
}
