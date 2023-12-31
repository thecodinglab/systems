{ pkgs, ... }: {
  programs.zathura = {
    enable = true;
    package = pkgs.zathura;

    options = {
      selection-clipboard = "clipboard";
    };
  };

  xdg.mimeApps.defaultApplications."application/pdf" = 
    [ "${pkgs.zathura}/share/applications/org.pwmt.zathura.desktop" ];
}
