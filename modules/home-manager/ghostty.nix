{
  config,
  pkgs,
  lib,
  ...
}:
{
  options.custom.ghostty = {
    enable = lib.mkEnableOption "enable ghostty";
  };

  config = lib.mkIf config.custom.ghostty.enable {
    programs.ghostty = {
      enable = true;
      settings = {
        theme = "dark:catppuccin-mocha,light:catppuccin-latte";
        shell-integration = "zsh";

        quit-after-last-window-closed = true;

        window-padding-x = 2;
        window-padding-y = 4;

        auto-update = "off";
      };
    };
  };
}
