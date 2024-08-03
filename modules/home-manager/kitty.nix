{
  config,
  pkgs,
  lib,
  ...
}:
{
  options.custom.kitty = {
    enable = lib.mkEnableOption "enable kitty";
  };

  config = lib.mkIf config.custom.kitty.enable {
    programs.kitty = {
      enable = true;

      settings = pkgs.lib.mkMerge [
        {
          clipboard_control = "write-clipboard write-primary read-clipboard-ask read-primary-ask";
          allow_remote_control = "socket-only";
          listen_on = "unix:/tmp/kitty";

          window_padding_width = "2 4";
        }
        (lib.mkIf pkgs.stdenv.isDarwin {
          macos_show_window_title_in = "none";
          hide_window_decorations = "titlebar-only";
        })
      ];
    };
  };
}
