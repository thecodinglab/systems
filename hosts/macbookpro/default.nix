{ ... }:
{
  imports = [ ../../profiles/darwin/workstation.nix ];

  networking = {
    computerName = "Florian’s MacBook Pro";
    hostName = "Florians-MacBook-Pro";
    localHostName = "Florians-MacBook-Pro";
  };

  home-manager.users.florian = ./home.nix;

  system.defaults.dock.autohide = true;
  system.defaults.dock.autohide-delay = 0.2;

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

  homebrew = {
    casks = [
      "spotify"

      "figma"
      "linear"
      "orbstack"

      "helium-browser"
      "google-chrome"
      "whatsapp"

      "chatgpt"
      "codex-app"
    ];
    masApps = {
      "Pages" = 409201541;
      "Numbers" = 409203825;
      "Slack" = 803453959;
    };
  };
}
