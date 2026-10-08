{
  config,
  lib,
  pkgs,
  ...
}:
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

        # Kernel NT synchronisation primitives: Proton builds with ntsync
        # support otherwise fall back to fsync/esync. Neither systemd nor
        # nixpkgs ship a rule for the device node; it has to sort before
        # 73-seat-late for the uaccess ACL to also apply on hotplug.
        boot.kernelModules = [ "ntsync" ];
        services.udev.packages = [
          (pkgs.writeTextDir "lib/udev/rules.d/70-ntsync.rules" ''
            KERNEL=="ntsync", MODE="0660", TAG+="uaccess"
          '')
        ];

        programs = {
          gamemode = {
            enable = true;
            # the performance governor is always on (desktop/tuning.nix), so
            # what gamemode still adds is priority over background work like
            # nix builds
            settings.general.renice = 10;
          };

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
      }

      (lib.mkIf config.custom.nvidia.enable {
        boot.extraModprobeConfig = ''
          options nvidia NVreg_EnableGpuFirmware=0
        '';

        hardware.nvidia = {
          open = false;
          package = config.boot.kernelPackages.nvidiaPackages.latest;
        };
      })
    ]
  );
}
