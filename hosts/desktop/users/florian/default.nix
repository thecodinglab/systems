{ pkgs, home-manager, hyprland, hyprpaper, ... }:
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
  };

  imports = [
    (import ../../../../modules/common/ssh/authorized-keys.nix "florian")

    home-manager.nixosModules.home-manager
    {
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;

        users.florian = ({ ... }: {
          imports = [
            hyprpaper.homeManagerModules.hyprpaper
            ../../../../users/florian/configuration.nix
          ];

          programs.default = {
            enable = true;
            enableDevelopment = true;
            enableGaming = true;
          };
        });

        extraSpecialArgs = { inherit hyprland hyprpaper; };
      };
    }
  ];
}
