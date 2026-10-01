# everything both Macs share; hosts only add what differs
{
  inputs,
  pkgs,
  keys,
  ...
}:
{
  programs.gnupg.agent.enable = true;

  environment.systemPackages = [
    pkgs.ghostty-bin
    pkgs.obsidian
  ];

  system.primaryUser = "florian";
  users.users.florian = {
    name = "florian";
    # without trailing slash: home-manager uses it as home.homeDirectory
    home = "/Users/florian";

    openssh.authorizedKeys.keys = [ keys.personal ];
  };

  security.sudo.extraConfig = ''
    %admin ALL=(ALL) NOPASSWD: ALL
  '';

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

  nix-homebrew = {
    enable = true;
    enableRosetta = false;

    user = "florian";

    taps = {
      "homebrew/homebrew-core" = inputs.homebrew-core;
      "homebrew/homebrew-cask" = inputs.homebrew-cask;
      "homebrew/homebrew-bundle" = inputs.homebrew-bundle;
    };

    mutableTaps = false;
  };

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
