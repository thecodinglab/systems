{
  config,
  pkgs,
  lib,
  ...
}:
{
  options.custom.desktop = {
    enable = lib.mkEnableOption "enable desktop configuration";
  };

  config =
    let
      backgroundImageName = "Pictures/wallpaper.jpg";
      backgroundImagePath = "${config.home.homeDirectory}/${backgroundImageName}";

      wallpaperBlurred = pkgs.runCommand "wallpaper-blurred.png" { buildInputs = [ pkgs.ffmpeg ]; } ''
        ffmpeg -y -i ${./wallpaper.jpg} -vf "gblur=sigma=30:steps=3" $out
      '';
    in
    lib.mkIf config.custom.desktop.enable {
      xsession.windowManager.bspwm = lib.mkIf config.xsession.windowManager.bspwm.enable {
        startupPrograms = [ "${lib.getExe pkgs.feh} --bg-fill ${backgroundImagePath}" ];
      };

      services.hyprpaper = lib.mkIf config.wayland.windowManager.hyprland.enable {
        enable = true;
        settings = {
          splash = false;

          preload = [ backgroundImagePath ];
          wallpaper = [ ",${backgroundImagePath}" ];
        };
      };

      programs.hyprlock = lib.mkIf config.programs.hyprlock.enable {
        settings.background.path = "${wallpaperBlurred}";
      };

      programs.kitty.settings = lib.mkIf config.programs.kitty.enable {
        background_image = "${wallpaperBlurred}";
        background_image_layout = "cscaled";
        background_tint = "0.8";
      };

      home.file.${backgroundImageName} = {
        enable = true;
        source = ./wallpaper.jpg;
      };
    };
}
