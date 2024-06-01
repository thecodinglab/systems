{ config, lib, ... }:
let sources = import ./npins; in
{
  wayland.windowManager.hyprland.settings = lib.mkIf config.catppuccin.enable {
    source = [
      "${sources.hyprland}/themes/${config.catppuccin.flavor}.conf"
      (builtins.toFile "hyprland-${config.catppuccin.accent}-accent.conf" ''
        $accent=''$${config.catppuccin.accent}
        $accentAlpha=''$${config.catppuccin.accent}Alpha
      '')
    ];

    general = {
      "col.active_border" = "$accent";
      "col.inactive_border" = "$surface0";
    };
  };
}
