{ pkgs, home-manager, root, ... }:
{
  users.users.florian = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    initialPassword = "changeme";

    shell = pkgs.bash;
  };

  imports = [
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
