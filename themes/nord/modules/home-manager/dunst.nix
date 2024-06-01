{ config, lib, ... }:
let
  colors = import ../../default.nix;
in
{
  services.dunst.settings = lib.mkIf config.nord.enable {
    global.frame_color = colors.hex.nord5;

    urgency_low = {
      background = colors.hex.nord0;
      foreground = colors.hex.nord4;
    };

    urgency_normal = {
      background = colors.hex.nord0;
      foreground = colors.hex.nord4;
    };

    urgency_critical = {
      background = colors.hex.nord0;
      foreground = colors.hex.nord11;
    };
  };
}
