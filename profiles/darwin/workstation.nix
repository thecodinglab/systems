# everything both Macs share; hosts only add what differs
{
  config,
  inputs,
  pkgs,
  keys,
  ...
}:
{
  programs.gnupg.agent.enable = true;

  system.primaryUser = "florian";
  users.users.florian = {
    name = "florian";
    # without trailing slash: home-manager uses it as home.homeDirectory
    home = "/Users/florian";

    openssh.authorizedKeys.keys = [ keys.personal ];
  };

  # x86_64-linux builds go to the desktop (authorized in hosts/desktop). The
  # daemon connects as root, which has neither ~/.ssh/config nor the 1password
  # agent, hence its own key (from sops, see keys.nixBuilders) and host entry.
  sops.secrets.nix_builder_ssh_key = { };
  nix = {
    distributedBuilds = true;
    settings.builders-use-substitutes = true;
    buildMachines = [
      {
        hostName = "desktop";
        protocol = "ssh-ng";
        sshUser = "florian";
        sshKey = config.sops.secrets.nix_builder_ssh_key.path;
        systems = [ "x86_64-linux" ];
        maxJobs = 8;
        speedFactor = 2;
        supportedFeatures = [
          "big-parallel"
          "kvm"
          "nixos-test"
          "benchmark"
        ];
      }
    ];
  };
  programs.ssh = {
    extraConfig = ''
      Host desktop
        HostName 192.168.48.10
    '';
    knownHosts.desktop = {
      hostNames = [
        "desktop"
        "192.168.48.10"
      ];
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOoh3EBcxypmphIIht1rlm4hKJClIKo72by+X93f8fTJ";
    };
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
    taps = builtins.attrNames config.nix-homebrew.taps;
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
