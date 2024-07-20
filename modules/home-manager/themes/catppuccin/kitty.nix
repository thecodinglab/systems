{ config, lib, ... }:
let
  sources = import ./npins;
in
{
  programs.kitty.settings = lib.mkIf config.custom.catppuccin.enable {
    include = "${sources.kitty}/themes/${config.custom.catppuccin.flavor}.conf";
  };
}
