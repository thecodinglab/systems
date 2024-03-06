let
  colors = {
    polar-night = {
      nord0 = "#2e3440";
      nord1 = "#3b4252";
      nord2 = "#434c5e";
      nord3 = "#4c566a";
    };

    snow-storm = {
      nord4 = "#d8dee9";
      nord5 = "#e5e9f0";
      nord6 = "#eceff4";
    };

    frost = {
      nord7 = "#8fbcbb";
      nord8 = "#88c0d0";
      nord9 = "#81a1c1";
      nord10 = "#5e81ac";
    };

    aurora = {
      red = "#bf616a"; # nord11
      orange = "#d08770"; # nord12
      yellow = "#ebcb8b"; # nord13
      green = "#a3be8c"; # nord14
      purple = "#b48ead"; # nord15
    };
  };

in
{
  font = "JetBrainsMono Nerd Font 9";

  default-bg = colors.polar-night.nord0;
  default-fg = colors.snow-storm.nord6;

  statusbar-bg = colors.polar-night.nord0;
  statusbar-fg = colors.snow-storm.nord6;

  inputbar-bg = colors.polar-night.nord0;
  inputbar-fg = colors.snow-storm.nord6;

  index-bg = colors.polar-night.nord0;
  index-fg = colors.snow-storm.nord6;
  index-active-bg = colors.polar-night.nord1;
  index-active-fg = colors.snow-storm.nord6;

  highlight-color = colors.frost.nord9;
  highlight-active-color = colors.aurora.yellow;

  notification-bg = colors.polar-night.nord0;
  notification-fg = colors.snow-storm.nord6;
  notification-warning-bg = colors.polar-night.nord0;
  notification-warning-fg = colors.aurora.orange;
  notification-error-bg = colors.aurora.red;
  notification-error-fg = colors.snow-storm.nord6;

  completion-bg = colors.polar-night.nord0;
  completion-fg = colors.snow-storm.nord6;
  completion-highlight-bg = colors.polar-night.nord1;
  completion-highlight-fg = colors.snow-storm.nord6;

  recolor = true;
  recolor-keephue = true;
  recolor-darkcolor = colors.snow-storm.nord6;
  recolor-lightcolor = colors.polar-night.nord1;
}
