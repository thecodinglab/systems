{ pkgs, lib, ... }: {
  programs.hyprland = {
    enable = true;
    xwayland.enable = false;
  };
}
