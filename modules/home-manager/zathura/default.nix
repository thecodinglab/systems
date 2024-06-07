{ pkgs, ... }: {
  programs.zathura = {
    enable = true;
    package = pkgs.zathura;

    options = {
      font = "JetBrainsMono Nerd Font 11";
      selection-clipboard = "clipboard";

      page-padding = 10;
    };
  };

  xdg.mimeApps.defaultApplications."application/pdf" =
    [ "${pkgs.zathura}/share/applications/org.pwmt.zathura.desktop" ];

  home.packages = with pkgs; [
    (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
  ];
}
