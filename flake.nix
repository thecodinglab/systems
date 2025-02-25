{
  description = "personal system configurations";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.05";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    homebrew = {
      url = "github:zhaofengli-wip/nix-homebrew";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        nix-darwin.follows = "darwin";
      };
    };
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
    homebrew-bundle = {
      url = "github:homebrew/homebrew-bundle";
      flake = false;
    };

    nixvim = {
      url = "github:nix-community/nixvim";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
        nix-darwin.follows = "darwin";
      };
    };

    terranix = {
      url = "github:terranix/terranix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:danth/stylix?rev=eb5f81756731a3eefa42b1caf494ba5a9c8aedb4";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
        tinted-kitty.follows = "tinted-kitty";
      };
    };
    tinted-kitty = {
      url = "github:tinted-theming/tinted-kitty?ref=06bb401fa9a0ffb84365905ffbb959ae5bf40805";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      darwin,
      homebrew,
      home-manager,
      terranix,
      sops-nix,
      stylix,
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
      packages = forAllSystems (
        system:
        import ./pkgs {
          pkgs = nixpkgs.legacyPackages.${system};
          inherit inputs;
        }
      );

      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-rfc-style);
      overlays = import ./overlays { inherit inputs; };

      nixosModules = import ./modules/nixos;
      darwinModules = import ./modules/darwin;
      homeManagerModules = import ./modules/home-manager;

      nixosConfigurations =
        let
          baseModules = nixpkgs.lib.attrValues outputs.nixosModules ++ [
            sops-nix.nixosModules.sops
            stylix.nixosModules.stylix
          ];
        in
        {
          desktop = nixpkgs.lib.nixosSystem {
            specialArgs = {
              inherit inputs outputs;
            };
            modules = baseModules ++ [ ./nixos/desktop/configuration.nix ];
          };

          server = nixpkgs.lib.nixosSystem {
            specialArgs = {
              inherit inputs outputs;
            };
            modules = baseModules ++ [ ./nixos/server/configuration.nix ];
          };

          apollo = nixpkgs.lib.nixosSystem {
            specialArgs = {
              inherit inputs outputs;
            };
            modules = baseModules ++ [ ./nixos/containers/apollo/configuration.nix ];
          };

          hestia = nixpkgs.lib.nixosSystem {
            specialArgs = {
              inherit inputs outputs;
            };
            modules = baseModules ++ [ ./nixos/containers/hestia/configuration.nix ];
          };

          hermes = nixpkgs.lib.nixosSystem {
            specialArgs = {
              inherit inputs outputs;
            };
            modules = baseModules ++ [ ./nixos/containers/hermes/configuration.nix ];
          };

          poseidon = nixpkgs.lib.nixosSystem {
            specialArgs = {
              inherit inputs outputs;
            };
            modules = baseModules ++ [ ./nixos/containers/poseidon/configuration.nix ];
          };
        };

      darwinConfigurations =
        let
          baseModules = nixpkgs.lib.attrValues outputs.darwinModules ++ [
            stylix.darwinModules.stylix
            homebrew.darwinModules.nix-homebrew
          ];
        in
        {
          macbookpro = darwin.lib.darwinSystem {
            system = "aarch64-darwin";
            specialArgs = {
              inherit inputs outputs;
            };
            modules = baseModules ++ [
              ./darwin/macbookpro/configuration.nix
              {
                nix-homebrew = {
                  enable = true;
                  enableRosetta = false;

                  user = "florian";

                  taps = {
                    "homebrew/homebrew-core" = inputs.homebrew-core;
                    "homebrew/homebrew-cask" = inputs.homebrew-cask;
                    "homebrew/homebrew-bundle" = inputs.homebrew-bundle;
                  };

                  mutableTaps = false;
                };
              }
            ];
          };
        };

      homeConfigurations =
        let
          baseModules = nixpkgs.lib.attrValues outputs.homeManagerModules ++ [
            sops-nix.homeManagerModules.sops
            stylix.homeManagerModules.stylix
          ];
        in
        {
          "florian@desktop" = home-manager.lib.homeManagerConfiguration {
            pkgs = nixpkgs.legacyPackages.x86_64-linux;
            extraSpecialArgs = {
              inherit inputs outputs;
            };
            modules = baseModules ++ [ ./home-manager/florian/configuration.nix ];
          };

          "florian@macbookpro" = home-manager.lib.homeManagerConfiguration {
            pkgs = nixpkgs.legacyPackages.aarch64-darwin;
            extraSpecialArgs = {
              inherit inputs outputs;
            };
            modules = baseModules ++ [ ./home-manager/florian/configuration.nix ];
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
