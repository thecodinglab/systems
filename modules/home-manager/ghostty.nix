{
  config,
  pkgs,
  lib,
  ...
}:
let
  palette = import ./theme/palette.nix;
in
{
  options.custom.ghostty = {
    enable = lib.mkEnableOption "enable ghostty";
  };

  config = lib.mkIf config.custom.ghostty.enable {
    # Ghostty is where the colours are decided: it follows the system
    # appearance and everything running in it -- bat, delta, fzf, the prompt,
    # tmux, btop -- draws in its sixteen colours, so one switch here switches
    # them all without any of them having to ask.
    stylix.targets.ghostty.colors.enable = false;

    programs.ghostty = {
      enable = true;
      package = if pkgs.stdenv.hostPlatform.isDarwin then pkgs.ghostty-bin else pkgs.ghostty;

      themes = lib.mapAttrs' (
        appearance: colors:
        lib.nameValuePair "system-${appearance}" {
          background = colors.base00;
          foreground = colors.base05;
          cursor-color = colors.base05;
          cursor-text = colors.base00;
          selection-background = palette.selection.${appearance};
          selection-foreground = colors.base05;

          # The base16 layout tinted-shell uses: 0 and 7 are the ground and
          # the ink, 8 the comments, 9-14 repeat 1-6, and 16-21 carry the
          # slots that do not fit in sixteen, which tmux and fzf draw their
          # raised grounds and faint rules with.
          palette = lib.imap0 (index: slot: "${toString index}=#${colors.${slot}}") [
            "base00"
            "base08"
            "base0B"
            "base0A"
            "base0D"
            "base0E"
            "base0C"
            "base05"
            "base03"
            "base08"
            "base0B"
            "base0A"
            "base0D"
            "base0E"
            "base0C"
            "base07"
            "base09"
            "base0F"
            "base01"
            "base02"
            "base04"
            "base06"
          ];
        }
      ) (removeAttrs palette [ "selection" ]);

      settings = {
        shell-integration = "zsh";
        theme = "light:system-light,dark:system-dark";

        quit-after-last-window-closed = true;

        # Text gets a margin from the window edge rather than running into
        # it, and the slack left over by the cell grid is shared out round
        # all four sides instead of piling up on the right and the bottom.
        window-padding-x = 10;
        window-padding-y = 8;
        window-padding-balance = true;

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
