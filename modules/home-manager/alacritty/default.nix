{ pkgs, alacritty, ... }:
{
  programs.alacritty =
    let
      fontFamily = "JetBrainsMono Nerd Font";
    in
    {
      enable = true;
      package = pkgs.alacritty;

      settings = {
        env.TERM = "xterm-256color";
        scrolling.history = 100000;
        live_config_reload = true;

        font = {
          size = alacritty.fontSize;
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

        key_bindings = [
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
            chars = "\\x1bb";
          }
          {
            key = "Right";
            mods = "Alt";
            chars = "\\x1bf";
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
