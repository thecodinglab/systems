{ config, pkgs, lib, ... }:
let
  backgroundImageName = "Pictures/wallpaper.jpg";
in
{
  xsession.windowManager.bspwm = lib.mkIf config.xsession.windowManager.bspwm.enable {
    startupPrograms = [
      "${lib.getExe pkgs.feh} --bg-fill ~/${backgroundImageName}"
    ];
  };

  services.hyprpaper = lib.mkIf config.wayland.windowManager.hyprland.enable {
    enable = true;
    settings = {
      preload = [
        "~/${backgroundImageName}"
      ];
      wallpaper = [
        ",~/${backgroundImageName}"
      ];
    };
  };

  home.file.${backgroundImageName} = {
    enable = true;
    source = ./wallpaper.jpg;
  };
}
