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

    # NOTE: remove once https://github.com/hyprwm/hyprlock/pull/376 is merged
    hyprlock = {
      url = "github:thecodinglab/hyprlock";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, flake-utils, darwin, home-manager, neovim-config, hyprlock, ... }@inputs:
    let
      specialArgs = {
        inherit neovim-config hyprlock;
      };

      baseModules = [
        ./overlays.nix
        ./proprietary-packages.nix
      ];

      containers = import ./hosts/containers inputs;

      systemConfigurations = {
        nixosConfigurations = {
          desktop = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = baseModules ++ [
              home-manager.nixosModules.home-manager
              ./hosts/desktop/configuration.nix
            ];
            inherit specialArgs;
          };

          server = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = baseModules ++ [
              home-manager.nixosModules.home-manager
              ./hosts/server/configuration.nix
            ];
            inherit specialArgs;
          };
        } // containers.nixosConfigurations;

        darwinConfigurations = {
          macbookpro = darwin.lib.darwinSystem {
            system = "aarch64-darwin";
            modules = baseModules ++ [
              home-manager.darwinModules.home-manager
              ./hosts/macbookpro
            ];
            inherit specialArgs;
          };
        };
      };

      osIndependent = flake-utils.lib.eachDefaultSystem (system:
        let pkgs = import nixpkgs { inherit system; }; in
        {
          packages = containers.packages system //
            (
              let sf = pkgs.callPackage ./pkgs/fonts/san-francisco.nix { }; in
              {
                apple-font-sf-pro = sf.pro;
                apple-font-sf-compact = sf.compact;
                apple-font-sf-mono = sf.mono;
                apple-font-sf-new-york = sf.ny;
              }
            );

          apps = containers.apps system;

          formatter = pkgs.nixpkgs-fmt;
        }
      );
    in
    systemConfigurations // osIndependent;
}
