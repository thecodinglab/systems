{ config, lib, ... }:
{
  options.custom.desktop = {
    enable = lib.mkEnableOption "enable desktop configuration";
  };

  config = lib.mkIf config.custom.desktop.enable {
    custom.desktop.wayland.enable = lib.mkDefault true;

    services.dbus.enable = true;

    environment.pathsToLink = [
      # link desktop portal definitions and applications
      "/share/xdg-desktop-portal"
      "/share/applications"
    ];
  };
}
