{ home-manager, root, ... }: {
  users.users.florian = {
    name = "florian";
    home = "/Users/florian/";
  };

  imports = [
    (import (root + "/modules/common/ssh/authorized-keys.nix") "florian")

    home-manager.darwinModules.home-manager
    {
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;

        users.florian = ({ ... }: {
          imports = [
            (root + "/modules/home-manager/alacritty")
            (root + "/modules/home-manager/develop")
            (root + "/modules/home-manager/fzf")
            (root + "/modules/home-manager/git")
            (root + "/modules/home-manager/lf")
            (root + "/modules/home-manager/tmux")
            (root + "/modules/home-manager/zsh")
          ];

          home.stateVersion = "23.11";
        });

        extraSpecialArgs = {
          inherit root;

          alacritty.fontSize = 12;
        };
      };
    }
  ];
}
