{ pkgs, ... }:
{
  config.programs.nixvim = import ../../pkgs/neovim/config.nix { inherit pkgs; };
}
