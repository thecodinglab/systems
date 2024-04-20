{ inputs, pkgs, ... }: {
  programs.hyprland = {
    enable = true;
    xwayland.enable = false;

    package = inputs.hyprland.packages.${pkgs.system}.hyprland;
  };
}
