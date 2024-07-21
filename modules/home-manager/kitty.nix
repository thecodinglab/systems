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

      font = {
        package = pkgs.fonts.apple-font-sf-mono;
        name = "SF Mono";
        size = if pkgs.stdenv.isDarwin then 14 else 12;
      };

      settings = pkgs.lib.mkMerge [
        (
          let
            background = pkgs.runCommand "wallpaper-blurred.png" { buildInputs = [ pkgs.ffmpeg ]; } ''
              ffmpeg -y \
                -i ${./wallpaper/wallpaper.jpg} \
                -vf "gblur=sigma=30" \
                $out
            '';
          in
          {
            dynamic_background_opacity = true;

            background_image = "${background}";
            background_image_layout = "cscaled";
            background_tint = "0.8";

            clipboard_control = "write-clipboard write-primary read-clipboard-ask read-primary-ask";

            allow_remote_control = "socket-only";
            listen_on = "unix:/tmp/kitty";
          }
        )
        (lib.mkIf pkgs.stdenv.isDarwin {
          macos_show_window_title_in = "none";
          hide_window_decorations = "titlebar-only";
          window_padding_width = 1;
        })
      ];
    };
  };
}
