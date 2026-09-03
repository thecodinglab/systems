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
      package = if pkgs.stdenv.isDarwin then pkgs.ghostty-bin else pkgs.ghostty;
      settings = {
        shell-integration = "zsh";
        theme = "light:Catppuccin Latte,dark:Catppuccin Mocha";

        quit-after-last-window-closed = true;

        window-padding-x = 2;
        window-padding-y = 4;

        auto-update = "off";

        background-blur = true;
        background-opacity-cells = false;

        keybind = [
          "shift+enter=text:\\x1b\\r"
        ];

        # Skip the "close this surface?" prompt and the resize size overlay.
        confirm-close-surface = false;
        resize-overlay = "never";

        # Propagate terminfo and TERM_PROGRAM into SSH sessions.
        shell-integration-features = "ssh-env";
      }
      // lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
        # Fix general slowness on hyprland
        # (https://github.com/ghostty-org/ghostty/discussions/3224).
        async-backend = "epoll";
      };
    };
  };
}
