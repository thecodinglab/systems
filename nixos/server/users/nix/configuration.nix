{
  inputs,
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

    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKrk+aYPC9+XPBzYI6uuxRbczvimV1Brclkic873p0Uv"
    ];
  };

  home-manager.users.nix = (
    { ... }:
    {
      home.stateVersion = "23.11";

      imports = lib.attrValues outputs.homeManagerModules;

      custom = {
        fzf.enable = true;
        tmux.enable = true;
        zsh.enable = true;
      };

      programs.btop.enable = true;
    }
  );
}
