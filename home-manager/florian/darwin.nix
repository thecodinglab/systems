{ pkgs, lib, ... }:
lib.mkIf pkgs.stdenv.isDarwin {
  targets.darwin.linkApps.enable = false;

  # adapted from https://github.com/nix-darwin/nix-darwin/blob/c48e963a5558eb1c3827d59d21c5193622a1477c/modules/system/applications.nix#L94-L111
  home.activation.aliasApplications =
    let
      app-folder = "$(echo ~/Applications)/Home Manager Apps";
    in
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      $DRY_RUN_CMD mkdir -p "${app-folder}"
      $DRY_RUN_CMD ${lib.getExe pkgs.rsync} --checksum --copy-unsafe-links --archive --delete --no-group --no-owner \
        "$newGenPath/home-path/Applications/" \
        "${app-folder}/"
    '';
}
