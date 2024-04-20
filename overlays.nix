{ neovim-config, ... }: {
  nixpkgs.overlays = [
    (import ./pkgs/spotify/overlay.nix)
    (import ./pkgs/obsidian/overlay.nix)

    (final: prev: {
      neovim = neovim-config.packages.${final.system}.default;
    })
  ];
}
