let
  theme = import ../../../themes/nord;
in
{
  font = "JetBrainsMono Nerd Font 9";

  default-bg = theme.hex.nord0;
  default-fg = theme.hex.nord6;

  statusbar-bg = theme.hex.nord0;
  statusbar-fg = theme.hex.nord6;

  inputbar-bg = theme.hex.nord0;
  inputbar-fg = theme.hex.nord6;

  index-bg = theme.hex.nord0;
  index-fg = theme.hex.nord6;
  index-active-bg = theme.hex.nord1;
  index-active-fg = theme.hex.nord6;

  highlight-color = theme.toRGBA255Color (theme.colors.nord9 // { a = 0.3; });
  highlight-active-color = theme.toRGBA255Color (theme.colors.nord13 // { a = 0.3; });

  notification-bg = theme.hex.nord0;
  notification-fg = theme.hex.nord6;
  notification-warning-bg = theme.hex.nord0;
  notification-warning-fg = theme.hex.nord12;
  notification-error-bg = theme.hex.nord11;
  notification-error-fg = theme.hex.nord6;

  completion-bg = theme.hex.nord0;
  completion-fg = theme.hex.nord6;
  completion-highlight-bg = theme.hex.nord1;
  completion-highlight-fg = theme.hex.nord6;

  recolor = true;
  recolor-keephue = true;
  recolor-darkcolor = theme.hex.nord6;
  recolor-lightcolor = theme.hex.nord1;
}
