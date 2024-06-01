{ config, lib, ... }:
let colors = import ../../default.nix; in
{
  programs.tofi.settings = lib.mkIf config.nord.enable {
    text-color = colors.hex.nord4;
    background-color = colors.hex.nord0;
    selection-color = colors.hex.nord8;
  };
}
