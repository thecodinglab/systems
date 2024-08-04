{ pkgs, nixvim }:
nixvim.legacyPackages.${pkgs.system}.makeNixvimWithModule {
  inherit pkgs;
  module = ./config.nix;
}
