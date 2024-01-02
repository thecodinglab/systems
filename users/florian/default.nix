{ pkgs, home-manager, root, ... }: {
  imports =
    [
      ./nixos
      home-manager.nixosModules.home-manager
      {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;

        home-manager.users = {
          florian = import ./home-manager;
        };

        home-manager.extraSpecialArgs = {
          root = root;
          pkgs = pkgs;
        };
      }
    ];
}
