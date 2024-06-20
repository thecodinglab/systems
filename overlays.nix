{ neovim-config, hyprlock, ... }: {
  nixpkgs.overlays = [
    (import ./pkgs/fonts/overlay.nix)

    (final: prev: {
      neovim = neovim-config.packages.${final.system}.default;
    })

    # NOTE: remove once https://github.com/hyprwm/hyprlock/pull/376 is merged
    (final: prev: {
      hyprlock = hyprlock.packages.${final.system}.default;
    })
  ];
}
