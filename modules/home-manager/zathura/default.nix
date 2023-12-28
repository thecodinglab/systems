{ pkgs, ... }: {
  programs.zathura = {
    enable = true;
    package = pkgs.zathura;
  };

  xdg.mimeApps.defaultApplications."application/pdf" = 
    [ "${pkgs.zathura}/share/applications/org.pwmt.zathura.desktop" ];
}
