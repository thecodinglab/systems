{ neovim-config, ... }: {
  nixpkgs.overlays = [
    (import ./pkgs/spotify/overlay.nix)
  ];
}
