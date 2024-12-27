{ config, pkgs, ... }:
{
  stylix = {
    polarity = "dark";
    image = ./wallpaper.jpg;
    base16Scheme = ./theme.yaml;

    cursor = {
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Classic";
    };

    fonts = {
      sizes = {
        desktop = 10;
        popups = 10;
        terminal = if pkgs.stdenv.isDarwin then 16 else 12;
      };

      serif = config.stylix.fonts.sansSerif;

      sansSerif = {
        package = pkgs.inter;
        name = "Inter";
      };

      monospace = {
        package = pkgs.nerd-fonts.fira-code;
        name = "FiraCode Nerd Font Mono";
      };

      emoji = {
        package = pkgs.noto-fonts-emoji;
        name = "Noto Color Emoji";
      };
    };
  };
}
