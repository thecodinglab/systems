{ pkgs, ... }: {
  programs.zathura = {
    enable = true;
    package = pkgs.zathura;

    options = {
      font = "SF Mono 10";
      selection-clipboard = "clipboard";

      page-padding = 10;
    };
  };

  xdg.mimeApps.defaultApplications."application/pdf" =
    [ "${pkgs.zathura}/share/applications/org.pwmt.zathura.desktop" ];

  home.packages = [
    pkgs.apple-font-sf-mono
  ];
}
