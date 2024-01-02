{ pkgs, lib, root, ... }:
let
  generalModules = [
    # Command Line Applications
    (root + "/modules/home-manager/alacritty")
    (root + "/modules/home-manager/tmux")
    (root + "/modules/home-manager/zsh")
    (root + "/modules/home-manager/fzf")
    (root + "/modules/home-manager/lf")

    # Desktop Applications
    (root + "/modules/home-manager/zathura")
  ];

  linuxSpecificModules = [
    # Desktop Environment
    (root + "/modules/home-manager/i3")
  ];

  darwinSpecificModules = [
  ];
in
{
  home.stateVersion = "23.11";

  imports =
    generalModules
    ++ lib.optionals pkgs.stdenv.isLinux linuxSpecificModules
    ++ lib.optionals pkgs.stdenv.isDarwin darwinSpecificModules;

  home.file.".background-image" = {
    enable = true;
    source = (root + "/wallpaper.jpg");
  };
}
