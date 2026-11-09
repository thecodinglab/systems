{
  config,
  pkgs,
  lib,
  ...
}:
let
  palette = import ./palette.nix;
in
{
  stylix = {
    # The desktop is dark like the photo it is set in. The terminals switch
    # with the system appearance on their own, see the ghostty module.
    polarity = "dark";
    image = ./wallpaper.jpg;
    base16Scheme = {
      system = "base16";
      name = "Quiet Colour Dark";
      author = "florian";
      variant = "dark";
      palette = palette.dark;
    };

    # A terminal is content, and text has to read over whatever is behind
    # it. Tiled on hyprland that is only ever the wallpaper, and at 92% the
    # comments still clear 4.5:1 over its brightest part, the snow on the
    # peak -- the same floor the shell's glass is held to. On a mac windows
    # overlap, and over a white page anything below opaque drops comments
    # and red under 4.5:1, so there it is solid.
    opacity.terminal = if pkgs.stdenv.hostPlatform.isLinux then 0.92 else 1.0;

    cursor = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Classic";
      size = 20;
    };

    fonts = {
      # 10pt at 96dpi is 13.3px, the 13pt body a mac sets at 72dpi
      sizes = {
        desktop = 10;
        popups = 10;
        terminal = 14;
      };

      serif = config.stylix.fonts.sansSerif;

      # SF Pro is licensed for Apple platforms only; Inter was drawn for
      # screens on the same principles and has a display cut for large sizes
      sansSerif = {
        package = pkgs.inter;
        name = "Inter";
      };

      monospace = {
        package = pkgs.nerd-fonts.jetbrains-mono;
        name = "JetBrainsMono Nerd Font Mono";
      };

      emoji = {
        package = pkgs.noto-fonts-color-emoji;
        name = "Noto Color Emoji";
      };
    };

    # These follow the terminal's own sixteen colours instead of being handed
    # the dark palette, so they switch with it, see the ghostty module.
    targets = {
      bat.enable = false;
      btop.enable = false;
      fzf.enable = false;
      starship.enable = false;
      tmux.enable = false;
      yazi.enable = false;
    };
  };

  # the terminal's colours, both appearances
  programs.bat.config.theme = "base16";
  programs.btop.settings = {
    color_theme = "TTY";
    theme_background = false;
  };
}
