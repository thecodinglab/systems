{ config, lib, ... }:
let
  sources = import ./npins;
  colors =
    (lib.importJSON "${sources.palette}/palette.json").${config.custom.catppuccin.flavor}.colors;

  makeRGBA = (
    {
      r,
      g,
      b,
      a,
    }:
    "rgba(${toString r}, ${toString g}, ${toString b}, ${toString a})"
  );
in
{
  programs.zathura = lib.mkIf config.custom.catppuccin.enable {
    options = {
      recolor-keephue = true;
      default-bg = makeRGBA (colors.base.rgb // { a = 0.8; });
    };

    extraConfig = builtins.readFile "${sources.zathura}/src/catppuccin-${config.custom.catppuccin.flavor}";
  };
}