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
      inputs.nixpkgs.follows = "nixpkgs";
    };

    terranix = {
      url = "github:terranix/terranix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
      };
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nix-darwin,
      home-manager,
      terranix,
      ...
    }@inputs:
    let
      inherit (self) outputs;

      systems = [
        "aarch64-linux"
        "x86_64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];

      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      packages = forAllSystems (system: import ./pkgs nixpkgs.legacyPackages.${system});
      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-rfc-style);
      overlays = import ./overlays { inherit inputs; };

      nixosModules = import ./modules/nixos;
      darwinModules = import ./modules/darwin;
      homeManagerModules = import ./modules/home-manager;

      nixosConfigurations = {
        desktop = nixpkgs.lib.nixosSystem {
          specialArgs = {
            inherit inputs outputs;
          };

          modules = nixpkgs.lib.attrValues outputs.nixosModules ++ [ ./nixos/desktop/configuration.nix ];
        };

        server = nixpkgs.lib.nixosSystem {
          specialArgs = {
            inherit inputs outputs;
          };

          modules = nixpkgs.lib.attrValues outputs.nixosModules ++ [
            ./nixos/server/configuration.nix
            home-manager.nixosModules.home-manager
          ];
        };

        apollo = nixpkgs.lib.nixosSystem {
          specialArgs = {
            inherit inputs outputs;
          };

          modules = nixpkgs.lib.attrValues outputs.nixosModules ++ [
            ./nixos/containers/apollo/configuration.nix
          ];
        };
      };

      darwinConfigurations = {
        macbookpro = nix-darwin.lib.darwinSystem {
          system = "aarch64-darwin";

          specialArgs = {
            inherit inputs outputs;
            something = outputs;
          };

          modules = nixpkgs.lib.attrValues outputs.darwinModules ++ [
            ./darwin/macbookpro/configuration.nix
            home-manager.darwinModules.home-manager
          ];
        };
      };

      homeConfigurations = {
        "florian@desktop" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.x86_64-linux;

          extraSpecialArgs = {
            inherit inputs outputs;
          };

          modules = nixpkgs.lib.attrValues outputs.homeManagerModules ++ [
            ./home-manager/florian/configuration.nix
          ];
        };

        "florian@macbookpro" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.aarch64-darwin;

          extraSpecialArgs = {
            inherit inputs outputs;
          };

          modules = nixpkgs.lib.attrValues outputs.homeManagerModules ++ [
            ./home-manager/florian/configuration.nix
          ];
        };
      };

      terraformConfiguration = forAllSystems (
        system:
        terranix.lib.terranixConfiguration {
          inherit system;

          extraArgs = {
            lib = import ./infra/lib nixpkgs.lib;
          };

          modules = [
            ./infra/provider.nix
            ./infra/apollo.nix
            ./infra/hermes.nix
            ./infra/hestia.nix
            ./infra/poseidon.nix
          ];
        }
      );

      apps = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          mkTerraformCmd =
            cmd:
            toString (
              pkgs.writers.writeBash "apply" ''
                if [[ -e config.tf.json ]]; then rm -f config.tf.json; fi
                cp ${self.terraformConfiguration.${system}} config.tf.json

                ${pkgs.lib.getExe pkgs.opentofu} init
                ${pkgs.lib.getExe pkgs.opentofu} ${cmd} $@
              ''
            );
        in
        {
          plan = {
            type = "app";
            program = mkTerraformCmd "plan";
          };
          apply = {
            type = "app";
            program = mkTerraformCmd "apply";
          };
        }
      );
    };
}
