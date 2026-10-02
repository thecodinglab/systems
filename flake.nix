{
  description = "personal system configurations";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-26.05";
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
      url = "github:nix-community/nixvim";
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

    devtools = {
      url = "github:thecodinglab/devtools";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    shell = {
      url = "github:thecodinglab/shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprland = {
      url = "github:hyprwm/hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    tether = {
      url = "github:zackb/tether";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # private repositories, fetched with the git credential helper (gh)
    kakeibo = {
      url = "git+https://github.com/thecodinglab/kakeibo";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    xcloud = {
      url = "git+https://github.com/studio-ch/xcloud";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        nix-darwin.follows = "darwin";
        sops-nix.follows = "sops-nix";
      };
    };

    # per-machine experiments that are never committed, see local/README.md
    local = {
      url = "path:./local";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      terranix,
      sops-nix,
      stylix,
      ...
    }@inputs:
    let
      inherit (self) outputs;
      inherit (nixpkgs.lib) genAttrs;

      helpers = import ./lib { inherit inputs outputs; };
      inherit (helpers) pkgsFor;

      systems = [
        "aarch64-linux"
        "x86_64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];

      forAllSystems = genAttrs systems;
    in
    {
      packages = forAllSystems (
        system:
        import ./pkgs {
          pkgs = pkgsFor system;
          inherit inputs;
        }
      );

      formatter = forAllSystems (system: (pkgsFor system).nixfmt);
      overlays = import ./overlays { inherit inputs; };

      nixosModules = import ./modules/nixos // {
        sops = sops-nix.nixosModules.sops;
        stylix = stylix.nixosModules.stylix;
        tether = inputs.tether.nixosModules.default;
      };

      darwinModules = import ./modules/darwin // {
        stylix = stylix.darwinModules.stylix;
        homebrew = inputs.homebrew.darwinModules.nix-homebrew;
      };

      homeManagerModules = (import ./modules/home-manager) // {
        sops = sops-nix.homeManagerModules.sops;
        stylix = stylix.homeModules.stylix;
        shell = inputs.shell.homeModules.default;
      };

      # adding a host: create hosts/<name>/default.nix and list its name here
      nixosConfigurations =
        genAttrs [ "desktop" "server" ] helpers.mkNixos
        // genAttrs [ "apollo" "hermes" "hestia" ] helpers.mkContainer;

      darwinConfigurations = genAttrs [ "macbookpro" "macmini" ] helpers.mkDarwin;

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
          ];
        }
      );

      apps = forAllSystems (
        system:
        let
          pkgs = pkgsFor system;
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
