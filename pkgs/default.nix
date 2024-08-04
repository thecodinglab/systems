{ pkgs, nixvim, ... }:
{
  fonts = pkgs.callPackage ./fonts/san-francisco.nix { };
  neovim = import ./neovim/package.nix { inherit pkgs nixvim; };
}
