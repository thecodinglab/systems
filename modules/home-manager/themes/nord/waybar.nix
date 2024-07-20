{ config, lib, ... }:
let
  colors = import ../../default.nix;
in
{
  programs.waybar = lib.mkIf config.nord.enable {
    style = ''
      * {
        font-family: SF Pro;
        font-size: 14px;
        font-weight: 500;

        border: none;
        border-radius: 0;

        color: ${colors.hex.nord4};
      }

      window#waybar {
        background: ${colors.hex.nord0};
        color: ${colors.hex.nord4};
      }

      button:hover {
        background: ${colors.hex.nord2};
        box-shadow: none;
      }

      #workspaces {
        background: ${colors.hex.nord0};
        color: ${colors.hex.nord4};
      }

      #workspaces button.active {
        background: ${colors.hex.nord10};
      }

      #workspaces button.urgent {
        background: ${colors.hex.nord11};
      }

      button {
        padding: 0 5px;
      }
    '';
  };
}
