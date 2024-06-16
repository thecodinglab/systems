{ ... }: {
  users.users.florian = {
    name = "florian";
    home = "/Users/florian/";
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;

    users.florian = ({ ... }: {
      imports = [
        ../../../../users/florian/configuration.nix
      ];

      ########################
      # Customisations       #
      ########################

      programs = {
        default = {
          enable = true;
          enableDevelopment = true;
          enablePhotography = true;
        };

        alacritty.settings = {
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

        kitty.settings = {
          macos_show_window_title_in = "none";
          hide_window_decorations = "titlebar-only";
          window_padding_width = 1;
        };
      };
    });
  };

  imports = [
    (import ../../../../modules/common/ssh/authorized-keys.nix "florian")
  ];
}
