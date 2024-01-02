{
  description = "personal system configurations";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    darwin.url = "github:lnl7/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = attrs@{ self, nixpkgs, darwin, home-manager, flake-utils, ... }: {
    nixosConfigurations = {
      desktop = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [ ./proprietary-packages.nix ./systems/desktop ];
        specialArgs = attrs // {
          root = builtins.toString ./.;
        };
      };
    };

    darwinConfigurations = {
      mbp = darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        modules = [ ./proprietary-packages.nix ./systems/macbookpro ];
        specialArgs = attrs // {
          root = builtins.toString ./.;
        };
      };
    };
  } //
  flake-utils.lib.eachDefaultSystem (system: {
    formatter = nixpkgs.legacyPackages.${system}.nixpkgs-fmt;
  });
}
