let
  theme = import ../../../themes/nord;
in
{
  background = theme.nord0;
  foreground = theme.nord4;

  selection_foreground = theme.nord4;
  selection_background = theme.nord3;

  cursor = theme.nord4;
  cursor_text_color = theme.nord0;

  color0 = theme.nord0; # black
  color1 = theme.nord11; # red
  color2 = theme.nord14; # green
  color3 = theme.nord13; # yellow
  color4 = theme.nord10; # blue
  color5 = theme.nord15; # magenta
  color6 = theme.nord8; # cyan
  color7 = theme.nord5; # white

  color8 = theme.nord3; # bright black
  color9 = theme.nord11; # bright red
  color10 = theme.nord14; # bright green
  color11 = theme.nord13; # bright yellow
  color12 = theme.nord10; # bright blue
  color13 = theme.nord15; # bright magenta
  color14 = theme.nord8; # bright cyan
  color15 = theme.nord6; # bright white
}
