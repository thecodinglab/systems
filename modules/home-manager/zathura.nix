{
  config,
  pkgs,
  lib,
  ...
}:
{
  options.custom.zathura = {
    enable = lib.mkEnableOption "enable zathura";
  };

  config = lib.mkIf config.custom.zathura.enable {
    programs.zathura = {
      enable = true;
      package = pkgs.zathura;

      options = {
        font = config.stylix.fonts.monospace.name + " 10";
        selection-clipboard = "clipboard";

        page-padding = 10;
      };
    };

    xdg.mimeApps.defaultApplications."application/pdf" = [
      "${pkgs.zathura}/share/applications/org.pwmt.zathura.desktop"
    ];
  };
}
