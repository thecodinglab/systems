{ config, lib, ... }:
{
  config = lib.mkIf (config.custom.catppuccin.enable && config.programs.btop.enable) {
    programs.btop.settings.color_theme = "catppuccin.theme";
    xdg.configFile."btop/themes/catppuccin.theme".source = "${(import ./npins).btop}/themes/catppuccin_${config.custom.catppuccin.flavor}.theme";
  };
}
