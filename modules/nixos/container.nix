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

    networking.nftables.enable = false;

    environment.systemPackages = [ pkgs.neovim-minimal ];

    users.users.root = {
      shell = pkgs.zsh;

      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKrk+aYPC9+XPBzYI6uuxRbczvimV1Brclkic873p0Uv"
      ];
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
