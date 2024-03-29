{ pkgs, home-manager, root, ... }:
{
  users.users.florian = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "docker"
      "i2c" # required for dynamic-brightness service (i.e. ddcutil)
    ];
    initialPassword = "changeme";

    shell = pkgs.zsh;

    packages = with pkgs; [
      # Desktop Applications
      _1password-gui
      spotify
      steam
      obsidian

      # Build Tools
      gcc
      gnumake
      cmake

      # Git
      git
      git-crypt
      gh
      glab
      smartgithg

      # Languages
      go
      gopls
      gotools

      # Latex
      texliveFull
      texlab

      # AI
      ollama
    ];
  };

  imports = [
    (import (root + "/modules/common/ssh/authorized-keys.nix") "florian")

    home-manager.nixosModules.home-manager
    {
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;

        users.florian = ({ ... }: {
          imports = [
            (root + "/modules/home-manager/alacritty")
            (root + "/modules/home-manager/direnv")
            (root + "/modules/home-manager/fzf")
            (root + "/modules/home-manager/git")
            (root + "/modules/home-manager/kitty")
            (root + "/modules/home-manager/lf")
            (root + "/modules/home-manager/sioyek")
            (root + "/modules/home-manager/tmux")
            (root + "/modules/home-manager/zsh")

            (root + "/modules/home-manager/bspwm")
            (root + "/modules/home-manager/clipcat")
            (root + "/modules/home-manager/zathura")
          ];

          home.stateVersion = "23.11";
        });

        extraSpecialArgs = {
          inherit root;
        };
      };
    }
  ];
}
