{ config, lib, ... }:
let
  cfg = config.custom.gaming;
in
{
  options.custom.gaming = {
    enable = lib.mkEnableOption "enable gaming support";
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        hardware.graphics.enable32Bit = true;

        programs = {
          gamemode.enable = true;

          steam = {
            enable = true;
            gamescopeSession.enable = true;
          };

          gamescope = {
            enable = true;
            capSysNice = true;
          };
        };

        security.rtkit.enable = true;

        services.sunshine = {
          enable = true;
          autoStart = true;
          capSysAdmin = true;
          openFirewall = true;
        };

        zramSwap = {
          enable = true;
          memoryPercent = 50;
        };
      }

      (lib.mkIf config.custom.nvidia.enable {
        boot.extraModprobeConfig = ''
          options nvidia NVreg_EnableGpuFirmware=0
        '';

        hardware.nvidia.open = false;
      })
    ]
  );
}
