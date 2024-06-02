{ config, lib, ... }:
let
  sources = import ./npins;
  colors = (lib.importJSON "${sources.palette}/palette.json").${config.catppuccin.flavor}.colors;

  makeRGBA = ({ r, g, b }: "rgba(${toString r}, ${toString g}, ${toString b}, 1)");
in
{
  programs.zathura = lib.mkIf config.catppuccin.enable {
    options = {
      recolor-keephue = true;
      default-bg = makeRGBA colors.mantle.rgb;
    };

    extraConfig = builtins.readFile
      "${sources.zathura}/src/catppuccin-${config.catppuccin.flavor}";
  };
}
