{ config, lib, ... }:
{
  options.custom.chromium = {
    enable = lib.mkEnableOption "enable chromium";
  };

  config = lib.mkIf config.custom.chromium.enable {
    programs.chromium = {
      enable = true;

      commandLineArgs = [
        "--ozone-platform=wayland"
        "--enable-features=TouchpadOverscrollHistoryNavigation"
      ];

      extensions = [
        { id = "cjpalhdlnbpafiamejdnhcphjbkeiagm"; } # ublock origin
        { id = "aeblfdkhhhdcdjpifhhbdiojplfjncoa"; } # 1password
      ];
    };
  };
}
