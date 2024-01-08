{ pkgs, home-manager, root, ... }:
{
  users.users.florian = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    initialPassword = "";

    shell = pkgs.bash;
  };

  imports = [
    (import (root + "/modules/common/ssh/authorized-keys.nix") "florian")

    home-manager.nixosModules.home-manager
    {
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;

        users.florian = ({ ... }: {
          home.stateVersion = "23.11";
        });

        extraSpecialArgs = { inherit root; };
      };
    }
  ];
}
