{
  outputs,
  pkgs,
  lib,
  ...
}:
{
  users.users.nix = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "incus-admin"
    ];
    initialPassword = "changeme";

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

    users.nix = (
      { ... }:
      {
        home.stateVersion = "23.11";

        imports = lib.attrValues outputs.homeManagerModules;

        custom = {
          catppuccin.enable = true;
          fzf.enable = true;
          tmux.enable = true;
          zsh.enable = true;
        };

        programs.btop.enable = true;
      }
    );
  };
}
