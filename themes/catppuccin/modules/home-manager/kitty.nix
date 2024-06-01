{ config, lib, ... }:
let sources = import ./npins; in
{
  programs.kitty.settings = lib.mkIf config.catppuccin.enable {
    include = "${sources.kitty}/themes/${config.catppuccin.flavor}.conf";
  };
}
