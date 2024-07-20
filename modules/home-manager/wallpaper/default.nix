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
        settings.background.path = backgroundImagePath;
      };

      home.file.${backgroundImageName} = {
        enable = true;
        source = ./wallpaper.jpg;
      };
    };
}
