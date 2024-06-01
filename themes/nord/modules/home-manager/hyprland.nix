{ config, lib, ... }:
let
  colors = import ../../default.nix;
  mkHyprColor = color:
    "rgb(" + lib.strings.removePrefix "#" color + ")";
in
{
  wayland.windowManager.hyprland.settings = lib.mkIf config.nord.enable {
    "col.active_border" = mkHyprColor colors.hex.nord10;
    "col.inactive_border" = mkHyprColor colors.hex.nord0;
  };
}
