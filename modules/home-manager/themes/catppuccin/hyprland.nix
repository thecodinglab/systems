{ config, lib, ... }:
let
  sources = import ./npins;
in
{
  wayland.windowManager.hyprland.settings = lib.mkIf config.custom.catppuccin.enable {
    source = [
      "${sources.hyprland}/themes/${config.custom.catppuccin.flavor}.conf"
      (builtins.toFile "hyprland-${config.custom.catppuccin.accent}-accent.conf" ''
        $accent=''$${config.custom.catppuccin.accent}
        $accentAlpha=''$${config.custom.catppuccin.accent}Alpha
      '')
    ];

    general = {
      "col.active_border" = "$accent";
      "col.inactive_border" = "$surface0";
    };
  };
}
