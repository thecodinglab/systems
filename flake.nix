{
  description = "personal system configurations";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = attrs@{ self, nixpkgs, home-manager, ... }: {
    nixosConfigurations = {
      desktop = nixpkgs.lib.nixosSystem {
        system = "x84_64-linux";
        modules = [ ./proprietary-packages.nix ./systems/desktop ];
        specialArgs = attrs // { 
          root = builtins.toString ./.;
        };
      };
    };
  };
}
