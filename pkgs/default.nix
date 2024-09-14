{ pkgs, nixvim, ... }:
{
  fonts = pkgs.callPackage ./fonts/san-francisco.nix { };
  neovim = pkgs.callPackage ./neovim/package.nix { inherit nixvim; };
  zen-browser = pkgs.callPackage ./zen-browser { };
}
