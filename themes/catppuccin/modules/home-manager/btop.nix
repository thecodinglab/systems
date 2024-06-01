{ config, lib, ... }:
let
  sources = import ./npins;
  enable = config.catppuccin.enable && config.programs.btop.enable;
in
{
  programs.btop.settings = lib.mkIf enable {
    color_theme = "catppuccin.theme";
  };

  xdg.configFile."btop/themes/catppuccin.theme" = lib.mkIf enable {
    source = "${sources.btop}/themes/catppuccin_${config.catppuccin.flavor}.theme";
  };
}
