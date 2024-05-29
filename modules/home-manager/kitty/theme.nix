let
  theme = import ../../../themes/nord;
in
{
  background = theme.hex.nord0;
  foreground = theme.hex.nord4;

  selection_foreground = theme.hex.nord4;
  selection_background = theme.hex.nord3;

  cursor = theme.hex.nord4;
  cursor_text_color = theme.hex.nord0;

  color0 = theme.hex.nord0; # black
  color1 = theme.hex.nord11; # red
  color2 = theme.hex.nord14; # green
  color3 = theme.hex.nord13; # yellow
  color4 = theme.hex.nord10; # blue
  color5 = theme.hex.nord15; # magenta
  color6 = theme.hex.nord8; # cyan
  color7 = theme.hex.nord5; # white

  color8 = theme.hex.nord3; # bright black
  color9 = theme.hex.nord11; # bright red
  color10 = theme.hex.nord14; # bright green
  color11 = theme.hex.nord13; # bright yellow
  color12 = theme.hex.nord10; # bright blue
  color13 = theme.hex.nord15; # bright magenta
  color14 = theme.hex.nord8; # bright cyan
  color15 = theme.hex.nord6; # bright white
}
