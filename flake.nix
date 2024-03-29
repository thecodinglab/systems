{
  description = "personal system configurations";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    neovim-config = {
      url = "github:thecodinglab/neovim-config";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
      };
    };

    terranix = {
      url = "github:terranix/terranix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
      };
    };
  };

  outputs = inputs@{ self, nixpkgs, flake-utils, darwin, home-manager, neovim-config, terranix }:
    let
      specialArgs = {
        inherit home-manager neovim-config;
      };

      containers = import ./hosts/containers inputs;

      systemConfigurations = {
        nixosConfigurations = {
          desktop = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [ ./proprietary-packages.nix ./hosts/desktop/configuration.nix ];
            inherit specialArgs;
          };

          server = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [ ./hosts/server/configuration.nix ];
            inherit specialArgs;
          };
        } // containers.nixosConfigurations;

        darwinConfigurations = {
          macbookpro = darwin.lib.darwinSystem {
            system = "aarch64-darwin";
            modules = [ ./proprietary-packages.nix ./systems/macbookpro ];
            inherit specialArgs;
          };
        };
      };

      osIndependent = flake-utils.lib.eachDefaultSystem (system:
        let pkgs = import nixpkgs { inherit system; }; in
        {
          packages = containers.packages system;
          apps = containers.apps system;

          formatter = pkgs.nixpkgs-fmt;
        }
      );
    in
    systemConfigurations // osIndependent;
}
