{ config, lib, ... }:
let
  sources = import ./npins;
in
{
  programs.waybar = lib.mkIf config.custom.catppuccin.enable {
    style =
      (builtins.readFile "${sources.waybar}/themes/${config.custom.catppuccin.flavor}.css")
      + ''
        * {
          font-family: SF Pro;
          font-size: 14px;
          font-weight: 500;

          border: none;
          border-radius: 5px;

          color: @text;
        }

        window#waybar {
          background: transparent;
        }

        .modules-left, .modules-center, .modules-right {
          margin: 10px 30px;
          background: @base;
        }

        .modules-center, .modules-right {
          padding: 0 10px;
        }

        /* indiviual */

        #workspaces button {
          padding: 1px 10px;
          background: transparent;
        }

        #workspaces button:hover {
          background: @surface0;
          box-shadow: inherit;
        }

        #workspaces button.active {
          background: shade(@${config.custom.catppuccin.accent}, 0.5);
        }

        #workspaces button.urgent {
          background: shade(@red, 0.5);
        }

        #clock, #disk, #pulseaudio, #cpu, #memory, #network {
          padding: 0 2px;
        }
      '';
  };
}
