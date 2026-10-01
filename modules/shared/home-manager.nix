# home-manager integration shared by modules/darwin/common.nix and
# modules/nixos/common.nix; each of them imports the platform's home-manager
# module itself
{
  inputs,
  outputs,
  keys,
  lib,
  ...
}:
{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "hm-backup";
    extraSpecialArgs = { inherit inputs outputs keys; };
    sharedModules = lib.attrValues outputs.homeManagerModules ++ [
      # nixpkgs is shared with the system (useGlobalPkgs), stylix' overlays
      # would only trigger a warning there
      { stylix.overlays.enable = false; }
    ];
  };

  # stylix' home-manager module is already part of sharedModules above and
  # the theme is configured per user, not inherited from the system
  stylix.homeManagerIntegration.autoImport = false;
}
