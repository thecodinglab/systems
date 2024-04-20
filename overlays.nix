{ neovim-config, ... }: {
  nixpkgs.overlays = [
    (import ./pkgs/spotify/overlay.nix)

    (final: prev: {
      neovim = neovim-config.packages.${final.system}.default;
    })
  ];
}
