{ config, lib, ... }:
let
  sources = import ./npins;
in
{
  programs.git = lib.mkIf config.custom.catppuccin.enable {
    includes = [ { path = "${sources.delta}/catppuccin.gitconfig"; } ];
    delta.options.features = "catppuccin-${config.custom.catppuccin.flavor}";
  };

}
