{ config, lib, ... }:
let
  sources = import ./npins;
  enable = config.catppuccin.enable && config.programs.bat.enable;
in
{
  programs.bat.config = lib.mkIf enable {
    theme = "Catppuccin Mocha";
  };

  xdg.configFile."bat/themes/Catppuccin Mocha.tmTheme" = lib.mkIf enable {
    source = "${sources.bat}/themes/Catppuccin ${config.catppuccin.flavor}.tmTheme";
  };
}
