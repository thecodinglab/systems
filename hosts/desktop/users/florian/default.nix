{ pkgs, ... }:
{
  users.users.florian = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "docker"
      "libvirtd"
      "i2c" # required for dynamic-brightness service (i.e. ddcutil)
    ];
    initialPassword = "changeme";

    shell = pkgs.zsh;
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
          enableGaming = true;
        };

        kitty.settings.window_padding_width = "4 5";
      };
    });
  };

  imports = [
    (import ../../../../modules/common/ssh/authorized-keys.nix "florian")
  ];
}
