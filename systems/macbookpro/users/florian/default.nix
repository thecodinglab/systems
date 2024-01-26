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
          home.stateVersion = "23.11";

          imports = [
            (root + "/modules/home-manager/alacritty")
            (root + "/modules/home-manager/fzf")
            (root + "/modules/home-manager/git")
            (root + "/modules/home-manager/lf")
            (root + "/modules/home-manager/tmux")
            (root + "/modules/home-manager/zsh")
          ];

          ########################
          # Customisations       #
          ########################

          programs.alacritty.settings = {
            window = {
              decorations = "buttonless";
              padding = { x = 4; y = 2; };
            };

            font.size = 14;

            keyboard.bindings = [
              {
                key = "N";
                mods = "Command|Shift";
                action = "CreateNewWindow";
              }
              {
                key = "N";
                mods = "Command|Control";
                action = "SpawnNewInstance";
              }
              {
                key = "Left";
                mods = "Alt";
                chars = "\\u001bb";
              }
              {
                key = "Right";
                mods = "Alt";
                chars = "\\u001bf";
              }
            ];
          };
        });

        extraSpecialArgs = {
          inherit root;
        };
      };
    }
  ];
}
