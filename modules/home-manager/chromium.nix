{ config, lib, ... }:
{
  options.custom.chromium = {
    enable = lib.mkEnableOption "enable chromium";
  };

  config = lib.mkIf config.custom.chromium.enable {
    programs.chromium = {
      enable = true;
      extensions = [
        { id = "cjpalhdlnbpafiamejdnhcphjbkeiagm"; } # ublock origin
        { id = "aeblfdkhhhdcdjpifhhbdiojplfjncoa"; } # 1password
      ];
    };
  };
}
