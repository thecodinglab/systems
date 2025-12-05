{
  description = "personal system configurations";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.05";
    nixpkgs-bleeding.url = "github:nixos/nixpkgs/master";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    homebrew.url = "github:zhaofengli-wip/nix-homebrew";
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
      url = "github:nix-community/nixvim?ref=1cca516a54462a76fa117357d57cbb7ff5df0338";
      inputs.nixpkgs.follows = "nixpkgs";
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
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
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

      overlays = import ./overlays { inherit inputs; };

      mkPkgs =
        system:
        import nixpkgs {
          inherit system;

          overlays = [
            overlays.additions
            overlays.modifications
          ];

          config = {
            allowUnfreePredicate =
              pkg:
              builtins.elem (nixpkgs.lib.getName pkg) [
                "1password"
                "1password-cli"
                "spotify"
                "obsidian"

                # Work
                "slack"
                "postman"

                # AI
                "gemini-cli"
                "claude-code"

                # Gaming
                "steam"
                "steam-unwrapped"
                "steam-original"
                "steam-run"
                "discord"

                # Server
                "plexmediaserver"

                # Nvidia
                "nvidia-x11"
                "nvidia-settings"
                "cuda_cccl"
                "cuda_cudart"
                "cuda_nvcc"
                "libcublas"
              ];

            permittedInsecurePackages = [
              "beekeeper-studio-5.3.4"
            ];
          };
        };
    in
    {
      packages = forAllSystems (
        system:
        import ./pkgs {
          pkgs = mkPkgs system;
          inherit inputs;
        }
      );

      formatter = forAllSystems (system: (mkPkgs system).nixfmt-rfc-style);
      inherit overlays;

      nixosModules = import ./modules/nixos // {
        sops = sops-nix.nixosModules.sops;
        stylix = stylix.nixosModules.stylix;
      };

      darwinModules = import ./modules/darwin // {
        stylix = stylix.darwinModules.stylix;
        homebrew = homebrew.darwinModules.nix-homebrew;
      };

      homeManagerModules = (import ./modules/home-manager) // {
        sops = sops-nix.homeManagerModules.sops;
        stylix = stylix.homeModules.stylix;
      };

      nixosConfigurations = {
        desktop = nixpkgs.lib.nixosSystem {
          pkgs = mkPkgs "x86_64-linux";
          specialArgs = {
            inherit inputs outputs;
          };
          modules = nixpkgs.lib.attrValues outputs.nixosModules ++ [
            ./nixos/desktop/configuration.nix
          ];
        };

        server = nixpkgs.lib.nixosSystem {
          pkgs = mkPkgs "x86_64-linux";
          specialArgs = {
            inherit inputs outputs;
          };
          modules = nixpkgs.lib.attrValues outputs.nixosModules ++ [
            ./nixos/server/configuration.nix
          ];
        };

        apollo = nixpkgs.lib.nixosSystem {
          pkgs = mkPkgs "x86_64-linux";
          specialArgs = {
            inherit inputs outputs;
          };
          modules = nixpkgs.lib.attrValues outputs.nixosModules ++ [
            ./nixos/containers/apollo/configuration.nix
          ];
        };

        hestia = nixpkgs.lib.nixosSystem {
          pkgs = mkPkgs "x86_64-linux";
          specialArgs = {
            inherit inputs outputs;
          };
          modules = nixpkgs.lib.attrValues outputs.nixosModules ++ [
            ./nixos/containers/hestia/configuration.nix
          ];
        };

        hermes = nixpkgs.lib.nixosSystem {
          pkgs = mkPkgs "x86_64-linux";
          specialArgs = {
            inherit inputs outputs;
          };
          modules = nixpkgs.lib.attrValues outputs.nixosModules ++ [
            ./nixos/containers/hermes/configuration.nix
          ];
        };

        poseidon = nixpkgs.lib.nixosSystem {
          pkgs = mkPkgs "x86_64-linux";
          specialArgs = {
            inherit inputs outputs;
          };
          modules = nixpkgs.lib.attrValues outputs.nixosModules ++ [
            ./nixos/containers/poseidon/configuration.nix
          ];
        };
      };

      darwinConfigurations = {
        macbookpro = darwin.lib.darwinSystem {
          pkgs = mkPkgs "aarch64-darwin";
          specialArgs = {
            inherit inputs outputs;
          };
          modules = nixpkgs.lib.attrValues outputs.darwinModules ++ [
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

      homeConfigurations = {
        "florian@desktop" = home-manager.lib.homeManagerConfiguration {
          pkgs = mkPkgs "x86_64-linux";
          extraSpecialArgs = {
            inherit inputs outputs;
          };
          modules = nixpkgs.lib.attrValues outputs.homeManagerModules ++ [
            ./home-manager/florian/configuration.nix
          ];
        };

        "florian@macbookpro" = home-manager.lib.homeManagerConfiguration {
          pkgs = mkPkgs "aarch64-darwin";
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
          pkgs = mkPkgs system;
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
