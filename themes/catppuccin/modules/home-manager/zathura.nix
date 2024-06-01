{ config, lib, ... }:
let sources = import ./npins; in
{
  programs.zathura = lib.mkIf config.catppuccin.enable {
    options = {
      recolor-keephue = true;
    };

    extraConfig = builtins.readFile
      "${sources.zathura}/src/catppuccin-${config.catppuccin.flavor}";
  };
}
