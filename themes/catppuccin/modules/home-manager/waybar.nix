{ config, lib, ... }:
let sources = import ./npins; in
{
  programs.waybar = lib.mkIf config.catppuccin.enable {
    style = (builtins.readFile "${sources.waybar}/themes/${config.catppuccin.flavor}.css") + ''
      * {
        font-family: JetBrainsMono Nerd Font;
        font-size: 10pt;

        border: none;
        border-radius: 0;

        color: @text;
      }

      window#waybar {
        background: @base;
        color: @text;
      }

      button:hover {
        background: @surface0;
        box-shadow: none;
      }

      #workspaces {
        background: @base;
        color: @text;
      }

      #workspaces button.active {
        background: shade(@${config.catppuccin.accent}, 0.5);
      }

      #workspaces button.urgent {
        background: shade(@red, 0.5);
      }

      button {
        padding: 0 5px;
      }
    '';
  };
}
