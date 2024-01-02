{ root, ... }:
{
  home.stateVersion = "23.11";

  imports = [
    # Desktop Environment
    (root + "/modules/home-manager/i3")

    # Command Line Applications
    (root + "/modules/home-manager/alacritty")
    (root + "/modules/home-manager/tmux")
    (root + "/modules/home-manager/fzf")
    (root + "/modules/home-manager/lf")

    # Desktop Applications
    (root + "/modules/home-manager/zathura")
  ];

  home.file.".background-image" = {
    enable = true;
    source = (root + "/wallpaper.jpg");
  };
}
