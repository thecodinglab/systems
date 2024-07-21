{
  config,
  outputs,
  pkgs,
  lib,
  ...
}:
{
  options.custom.isContainer = lib.mkEnableOption "enable base container configuration ";

  config = lib.mkIf config.custom.isContainer {
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
            catppuccin.enable = true;
            fzf.enable = true;
            zsh.enable = true;
          };

          programs.btop.enable = true;
        };
    };
  };
}
