{ config, lib, ... }:
let
  colors = import ../../default.nix;
in
{
  programs.kitty.settings = lib.mkIf config.nord.enable {
    background = colors.hex.nord0;
    foreground = colors.hex.nord4;

    selection_foreground = colors.hex.nord4;
    selection_background = colors.hex.nord3;

    cursor = colors.hex.nord4;
    cursor_text_color = colors.hex.nord0;

    color0 = colors.hex.nord0; # black
    color1 = colors.hex.nord11; # red
    color2 = colors.hex.nord14; # green
    color3 = colors.hex.nord13; # yellow
    color4 = colors.hex.nord10; # blue
    color5 = colors.hex.nord15; # magenta
    color6 = colors.hex.nord8; # cyan
    color7 = colors.hex.nord5; # white

    color8 = colors.hex.nord3; # bright black
    color9 = colors.hex.nord11; # bright red
    color10 = colors.hex.nord14; # bright green
    color11 = colors.hex.nord13; # bright yellow
    color12 = colors.hex.nord10; # bright blue
    color13 = colors.hex.nord15; # bright magenta
    color14 = colors.hex.nord8; # bright cyan
    color15 = colors.hex.nord6; # bright white
  };
}
