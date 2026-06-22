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

  services.aerospace = {
    enable = true;

    settings = {
      gaps = {
        outer.left = 8;
        outer.bottom = 8;
        outer.top = 8;
        outer.right = 8;

        inner.horizontal = 8;
        inner.vertical = 8;
      };

      mode.main.binding = {
        alt-h = "focus left";
        alt-j = "focus down";
        alt-k = "focus up";
        alt-l = "focus right";

        alt-shift-h = "move left";
        alt-shift-j = "move down";
        alt-shift-k = "move up";
        alt-shift-l = "move right";

        alt-minus = "resize smart -50";
        alt-equal = "resize smart +50";

        alt-1 = "workspace 1";
        alt-2 = "workspace 2";
        alt-3 = "workspace 3";
        alt-4 = "workspace 4";
        alt-5 = "workspace 5";
        alt-6 = "workspace 6";
        alt-7 = "workspace 7";
        alt-8 = "workspace 8";
        alt-9 = "workspace 9";
        alt-0 = "workspace 10";

        alt-shift-1 = "move-node-to-workspace 1";
        alt-shift-2 = "move-node-to-workspace 2";
        alt-shift-3 = "move-node-to-workspace 3";
        alt-shift-4 = "move-node-to-workspace 4";
        alt-shift-5 = "move-node-to-workspace 5";
        alt-shift-6 = "move-node-to-workspace 6";
        alt-shift-7 = "move-node-to-workspace 7";
        alt-shift-8 = "move-node-to-workspace 8";
        alt-shift-9 = "move-node-to-workspace 9";
        alt-shift-0 = "move-node-to-workspace 10";

        alt-tab = "workspace-back-and-forth";
        alt-shift-tab = "move-workspace-to-monitor --wrap-around next";
      };

      on-window-detected =
        let
          floating = [
            "com.apple.finder"
            "com.apple.iCal"
            "com.apple.calculator"
            "com.apple.systempreferences"

            "com.spotify.client"
            "com.1password.1password"
            "com.tinyspeck.slackmacgap"

            "com.openai.chat"
            "com.openai.codex"
            "com.anthropic.claudefordesktop"
          ];
        in
        map (app: {
          "if".app-id = app;
          run = "layout floating";
        }) floating;

      workspace-to-monitor-force-assignment = {
        # left
        "1" = "DELL U2719D";
        "2" = "DELL U2719D";

        # center
        "3" = "main";
        "6" = "main";
        "7" = "main";
        "8" = "main";
        "9" = "main";
        "10" = "main";

        # right
        "4" = "main";
        "5" = "main";
      };

      on-focused-monitor-changed = [ "move-mouse monitor-lazy-center" ];
      on-focus-changed = [ "move-mouse window-lazy-center" ];
    };
  };

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
    };
    onActivation = {
      cleanup = "zap";
      upgrade = true;
    };
  };

  system.stateVersion = 5;
}
