{
  description = "personal system configurations";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
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
      root = builtins.toString ./.;

      specialArgs = {
        inherit root home-manager neovim-config;
      };

      containers = import ./containers (inputs // { inherit root; });

      systemConfigurations = {
        nixosConfigurations = {
          desktop = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [ ./proprietary-packages.nix ./systems/desktop ];
            inherit specialArgs;
          };

          server = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [ ./systems/server ];
            inherit specialArgs;
          };

          vm = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [ ./systems/vm ];
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
