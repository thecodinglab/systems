{
  description = "server container configurations";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    terranix = {
      url = "github:terranix/terranix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
      };
    };
  };

  outputs = { self, nixpkgs, flake-utils, terranix }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        moduleArgs = {};

        terraformConfiguration = terranix.lib.terranixConfiguration {
          inherit system;
          modules = [
            # initialize incus provider
            {
              terraform.required_providers.incus = {
                source = "lxc/incus";
                version = "0.0.2";
              };

              provider.incus = { };
            }

            # setup machines
            (import ./hermes/terraform.nix moduleArgs)
            (import ./apollo/terraform.nix moduleArgs)
          ];
        };

        makeOpenTofuCommandApp = (cmd: {
          type = "app";
          program = toString (pkgs.writers.writeBash cmd ''
            if [[ -e config.tf.json ]]; then rm config.tf.json; fi
            ln -s ${terraformConfiguration} config.tf.json
            ${pkgs.opentofu}/bin/tofu init
            ${pkgs.opentofu}/bin/tofu ${cmd}
          '');
        });
      in
      {
        packages = {
          terraform = terraformConfiguration;
        };

        apps = {
          plan = makeOpenTofuCommandApp "plan";
          apply = makeOpenTofuCommandApp "apply";
          destroy = makeOpenTofuCommandApp "destroy";
        };

        devShell = pkgs.mkShell {
          buildInputs = [
            pkgs.opentofu
          ];
        };

        formatter = pkgs.nixpkgs-fmt;
      }
    );
}
