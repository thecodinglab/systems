{
  config,
  lib,
  osConfig ? { },
  ...
}:
{
  options.custom.chromium = {
    enable = lib.mkEnableOption "enable chromium";
  };

  config = lib.mkIf config.custom.chromium.enable {
    programs.chromium = {
      enable = true;

      commandLineArgs = [
        "--ozone-platform=wayland"
        (
          "--enable-features="
          + lib.concatStringsSep "," (
            [ "TouchpadOverscrollHistoryNavigation" ]
            # chromium does not use VA-API on nvidia unless explicitly asked to
            ++ lib.optionals (osConfig.custom.nvidia.enable or false) [
              "VaapiVideoDecoder"
              "VaapiOnNvidiaGPUs"
              "AcceleratedVideoDecodeLinuxGL"
            ]
          )
        )
      ];

      extensions = [
        { id = "cjpalhdlnbpafiamejdnhcphjbkeiagm"; } # ublock origin
        { id = "aeblfdkhhhdcdjpifhhbdiojplfjncoa"; } # 1password
      ];
    };
  };
}
