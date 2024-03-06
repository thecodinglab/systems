{ pkgs, ... }: {
  programs.zathura = {
    enable = true;
    package = pkgs.zathura;

    options = {
      selection-clipboard = "clipboard";
    } // (import ./theme.nix);
  };

  xdg.mimeApps.defaultApplications."application/pdf" =
    [ "${pkgs.zathura}/share/applications/org.pwmt.zathura.desktop" ];

  home.packages = with pkgs; [
    (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
  ];
}
