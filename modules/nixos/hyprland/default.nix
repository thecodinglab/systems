{ pkgs, hyprland, ... }: {
  programs.hyprland = {
    enable = true;
    package = hyprland.packages.${pkgs.system}.hyprland;
  };
}
