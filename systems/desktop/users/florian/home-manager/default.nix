{ root, ... }:
{
  home.stateVersion = "23.11";

  imports = 
    [ (root + "/modules/home-manager/alacritty")
      (root + "/modules/home-manager/i3")
    ];

  home.file.".background-image" = {
    enable = true;
    source = (root + "/wallpaper.jpg");
  };
}
