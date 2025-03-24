{ config, pkgs, ... }:
{
  stylix = {
    polarity = "dark";
    image = ./wallpaper.jpg;
    base16Scheme = ./theme.yaml;

    cursor = {
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Classic";
      size = 20;
    };

    fonts = {
      sizes = {
        desktop = 10;
        popups = 10;
        terminal = if pkgs.stdenv.isDarwin then 14 else 10;
      };

      serif = config.stylix.fonts.sansSerif;

      sansSerif = {
        package = pkgs.inter;
        name = "Inter";
      };

      monospace = {
        package = pkgs.nerd-fonts.jetbrains-mono;
        name = "JetBrainsMono Nerd Font Mono";
      };

      emoji = {
        package = pkgs.noto-fonts-emoji;
        name = "Noto Color Emoji";
      };
    };
  };
}
