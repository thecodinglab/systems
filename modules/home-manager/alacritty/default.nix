{ pkgs, lib, ... }:
let
  fontFamily = "JetBrainsMono Nerd Font";
in
{
  programs.alacritty = {
    enable = true;
    package = pkgs.alacritty;

    settings = {
      env.TERM = "xterm-256color";
      scrolling.history = 100000;
      live_config_reload = true;

      font = {
        size = lib.mkDefault 10;
        normal = {
          family = fontFamily;
          style = "Regular";
        };
        bold = {
          family = fontFamily;
          style = "Bold";
        };
        italic = {
          family = fontFamily;
          style = "Italic";
        };
        bold_italic = {
          family = fontFamily;
          style = "BoldItalic";
        };
      };

      colors = import ./theme.nix;
    };
  };

  home.packages = with pkgs; [
    (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
  ];

  fonts.fontconfig.enable = true;
}
