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
      package = pkgs.zathura.override { useMupdf = true; };

      options = {
        # its status bar and inputbar are interface, not code
        font = config.stylix.fonts.sansSerif.name + " " + toString config.stylix.fonts.sizes.desktop;
        selection-clipboard = "clipboard";

        page-padding = 10;
      };
    };
  };
}
