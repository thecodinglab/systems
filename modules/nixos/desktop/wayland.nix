{
  config,
  pkgs,
  lib,
  ...
}:
{
  options.custom.desktop.wayland = {
    enable = lib.mkEnableOption "enable wayland configuration";
  };

  config = lib.mkIf config.custom.desktop.wayland.enable {
    programs.hyprland = {
      enable = true;
      xwayland.enable = true;
    };

    services.greetd = {
      enable = true;
      settings = {
        default_session = {
          command = "${lib.getExe pkgs.greetd.tuigreet} --time --remember --cmd ${lib.getExe pkgs.hyprland}";
          user = "greeter";
        };
      };
    };

    security.pam.services.hyprlock = { };
  };
}
