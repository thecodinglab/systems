{ pkgs, home-manager, root, ... }:
{
  users.users.florian = {
    isNormalUser = true;
    extraGroups = [ "wheel" "i2c" ];
    initialPassword = "changeme";

    shell = pkgs.zsh;

    packages = with pkgs; [
      # Desktop Applications
      _1password-gui
      spotify

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

      # Lanauges
      ltex-ls
      rnix-lsp

      go
      gopls
      gotools
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
            (root + "/modules/home-manager/fzf")
            (root + "/modules/home-manager/git")
            (root + "/modules/home-manager/lf")
            (root + "/modules/home-manager/tmux")
            (root + "/modules/home-manager/zsh")

            (root + "/modules/home-manager/clipcat")
            (root + "/modules/home-manager/i3")
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
