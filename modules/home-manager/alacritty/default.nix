args@{ pkgs, lib, ... }:
let
  fontFamily = "JetBrainsMono Nerd Font";

  defaultConfig = {
    fontSize = 10;
  };

  userConfig = args.alacritty or { };
  config = defaultConfig // userConfig;
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
        size = config.fontSize;
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

      keyboard.bindings = [
        {
          key = "N";
          mods = "Command|Shift";
          action = "CreateNewWindow";
        }
        {
          key = "N";
          mods = "Command|Control";
          action = "SpawnNewInstance";
        }
        {
          key = "Left";
          mods = "Alt";
          chars = "\\u001bb";
        }
        {
          key = "Right";
          mods = "Alt";
          chars = "\\u001bf";
        }
      ];

      colors = import ./theme.nix;
    };
  };

  home.packages = with pkgs; [
    (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
  ];

  fonts.fontconfig.enable = true;
}
