{ config, lib, ... }:
let
  colors = import ../../default.nix;
in
{
  programs.zathura.options = lib.mkIf config.nord.enable {
    default-bg = colors.hex.nord0;
    default-fg = colors.hex.nord6;

    statusbar-bg = colors.hex.nord0;
    statusbar-fg = colors.hex.nord6;

    inputbar-bg = colors.hex.nord0;
    inputbar-fg = colors.hex.nord6;

    index-bg = colors.hex.nord0;
    index-fg = colors.hex.nord6;
    index-active-bg = colors.hex.nord1;
    index-active-fg = colors.hex.nord6;

    highlight-color = colors.toRGBA255Color (colors.colors.nord9 // { a = 0.3; });
    highlight-active-color = colors.toRGBA255Color (colors.colors.nord13 // { a = 0.3; });

    notification-bg = colors.hex.nord0;
    notification-fg = colors.hex.nord6;
    notification-warning-bg = colors.hex.nord0;
    notification-warning-fg = colors.hex.nord12;
    notification-error-bg = colors.hex.nord11;
    notification-error-fg = colors.hex.nord6;

    completion-bg = colors.hex.nord0;
    completion-fg = colors.hex.nord6;
    completion-highlight-bg = colors.hex.nord1;
    completion-highlight-fg = colors.hex.nord6;

    recolor = true;
    recolor-keephue = true;
    recolor-darkcolor = colors.hex.nord6;
    recolor-lightcolor = colors.hex.nord1;
  };
}
