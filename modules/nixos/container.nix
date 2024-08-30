{
  config,
  inputs,
  outputs,
  pkgs,
  lib,
  ...
}:
{
  options.custom.isContainer = lib.mkEnableOption "enable base container configuration ";

  imports = [ inputs.home-manager.nixosModules.home-manager ];

  config = lib.mkIf config.custom.isContainer {
    nixpkgs.overlays = [
      outputs.overlays.additions
      outputs.overlays.modifications
    ];

    environment.systemPackages = [ pkgs.neovim.minimal ];

    users.users.root = {
      shell = pkgs.zsh;

      openssh.authorizedKeys.keys = lib.splitString "\n" (
        builtins.readFile (
          builtins.fetchurl {
            name = "ssh-authorized-keys-v1";
            url = "https://github.com/thecodinglab.keys";
            sha256 = "fobgOm3SyyClt8TM74PXjyM9JjbXrXJ52na7TjJdKA0=";
          }
        )
      );
    };

    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;

      users.root =
        { ... }:
        {
          home.stateVersion = "23.11";

          imports = lib.attrValues outputs.homeManagerModules;

          custom = {
            fzf.enable = true;
            zsh.enable = true;
          };

          programs.btop.enable = true;
        };
    };
  };
}
