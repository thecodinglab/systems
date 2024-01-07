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
  };

  outputs = { self, nixpkgs, darwin, home-manager, flake-utils, neovim-config }:
    let
      root = builtins.toString ./.;

      specialArgs = {
        inherit root home-manager neovim-config;
      };

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
        };

        darwinConfigurations = {
          macbookpro = darwin.lib.darwinSystem {
            system = "aarch64-darwin";
            modules = [ ./proprietary-packages.nix ./systems/macbookpro ];
            inherit specialArgs;
          };
        };
      };

      formatter =
        flake-utils.lib.eachDefaultSystem (system:
          let pkgs = import nixpkgs { inherit system; }; in
          {
            formatter = pkgs.nixpkgs-fmt;
          });
    in
    systemConfigurations // formatter;
}
