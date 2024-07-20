{ config, lib, ... }:
let
  sources = import ./npins;
  colors =
    (lib.importJSON "${sources.palette}/palette.json").${config.custom.catppuccin.flavor}.colors;
in
{
  programs.fzf.colors = lib.mkIf config.custom.catppuccin.enable {
    bg = colors.base.hex;
    "bg+" = colors.surface0.hex;
    fg = colors.text.hex;
    "fg+" = colors.text.hex;
    hl = colors.red.hex;
    "hl+" = colors.red.hex;

    spinner = colors.rosewater.hex;
    header = colors.red.hex;
    info = colors.mauve.hex;
    pointer = colors.rosewater.hex;
    marker = colors.rosewater.hex;
    prompt = colors.mauve.hex;
  };
}
