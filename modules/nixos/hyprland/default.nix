{ pkgs, hyprland, ... }: {
  programs.hyprland = {
    enable = true;
    xwayland.enable = false;

    package = hyprland.packages.${pkgs.system}.hyprland;
  };
}
