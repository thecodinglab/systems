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
        size = lib.mkDefault 12;
      };

      settings = {
        dynamic_background_opacity = true;
        background_opacity = "0.8";
        background_blur = 8;

        clipboard_control = "write-clipboard write-primary read-clipboard-ask read-primary-ask";

        allow_remote_control = "socket-only";
        listen_on = "unix:/tmp/kitty";
      };
    };
  };
}