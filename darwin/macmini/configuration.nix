{ pkgs, ... }:
{
  programs.gnupg.agent.enable = true;

  networking = {
    computerName = "Florian’s Mac mini";
    hostName = "Florians-Mac-Mini";
    localHostName = "Florians-Mac-Mini";
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

    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKrk+aYPC9+XPBzYI6uuxRbczvimV1Brclkic873p0Uv"
    ];
  };

  security.sudo.extraConfig = ''
    %admin ALL=(ALL) NOPASSWD: ALL
  '';

  system.defaults.dock.persistent-apps = [
    "/System/Cryptexes/App/System/Applications/Safari.app"
    "/System/Applications/Mail.app"
    "/System/Applications/Calendar.app"

    "/Applications/Nix Apps/Ghostty.app" # managed through nix-darwin

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
      "1password"
      "1password-cli"
      "claude"
    ];
    masApps = {
      "1Password for Safari" = 1569813296;
    };
    onActivation = {
      cleanup = "zap";
      upgrade = true;
    };
  };

  system.stateVersion = 5;
}
