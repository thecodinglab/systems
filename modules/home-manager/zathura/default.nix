{ pkgs, ... }: {
  programs.zathura = {
    enable = true;
    package = pkgs.zathura;

    options = {
      font = "JetBrainsMono Nerd Font 9";
      selection-clipboard = "clipboard";
    };
  };

  xdg.mimeApps.defaultApplications."application/pdf" =
    [ "${pkgs.zathura}/share/applications/org.pwmt.zathura.desktop" ];

  home.packages = with pkgs; [
    (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
  ];
}
