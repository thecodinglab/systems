let
  theme = import ../../../themes/nord;
in
{
  font = "JetBrainsMono Nerd Font 9";

  default-bg = theme.nord0;
  default-fg = theme.nord6;

  statusbar-bg = theme.nord0;
  statusbar-fg = theme.nord6;

  inputbar-bg = theme.nord0;
  inputbar-fg = theme.nord6;

  index-bg = theme.nord0;
  index-fg = theme.nord6;
  index-active-bg = theme.nord1;
  index-active-fg = theme.nord6;

  highlight-color = theme.nord9;
  highlight-active-color = theme.nord13;

  notification-bg = theme.nord0;
  notification-fg = theme.nord6;
  notification-warning-bg = theme.nord0;
  notification-warning-fg = theme.nord12;
  notification-error-bg = theme.nord11;
  notification-error-fg = theme.nord6;

  completion-bg = theme.nord0;
  completion-fg = theme.nord6;
  completion-highlight-bg = theme.nord1;
  completion-highlight-fg = theme.nord6;

  recolor = true;
  recolor-keephue = true;
  recolor-darkcolor = theme.nord6;
  recolor-lightcolor = theme.nord1;
}
