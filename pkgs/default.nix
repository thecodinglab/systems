{ pkgs, nixvim, ... }:
{
  fonts = pkgs.callPackage ./fonts/san-francisco.nix { };
  neovim = (pkgs.callPackage ./neovim { inherit nixvim; }).package;
}
