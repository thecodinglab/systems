{ pkgs, home-manager, root, ... }: {
  users.users.nix = {
    isNormalUser = true;
    extraGroups = [ "wheel" "incus-admin" ];
    initialPassword = "changeme";

    shell = pkgs.zsh;
  };

  imports = [
    (import (root + "/modules/common/ssh/authorized-keys.nix") "nix")

    home-manager.nixosModules.home-manager
    {
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;

        users.nix = ({ ... }: {
          imports = [
            (root + "/modules/home-manager/tmux")
            (root + "/modules/home-manager/zsh")
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
