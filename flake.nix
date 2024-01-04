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

  outputs = attrs@{ self, nixpkgs, darwin, home-manager, flake-utils, neovim-config }:
    let
      root = builtins.toString ./.;
    in
    {
      nixosConfigurations = {
        desktop = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [ ./proprietary-packages.nix ./systems/desktop ];
          specialArgs = attrs // {
            inherit root;
          };
        };
      };

      darwinConfigurations = {
        macbookpro = darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          modules = [ ./proprietary-packages.nix ./systems/macbookpro ];
          specialArgs = attrs // {
            inherit root;
          };
        };
      };
    } //
    flake-utils.lib.eachDefaultSystem (system:
      let pkgs = import nixpkgs { inherit system; }; in
      {
        formatter = pkgs.nixpkgs-fmt;
      });
}
