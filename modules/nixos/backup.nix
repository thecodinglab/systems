{ config, lib, ... }:
{
  options.custom.backup = {
    enable = lib.mkEnableOption "enable periodic backups";
  };

  config = lib.mkIf config.custom.backup.enable {
    services.snapper = {
      snapshotInterval = "hourly";
      cleanupInterval = "7d";

      snapshotRootOnBoot = true;
      persistentTimer = false;

      configs = {
        root = {
          SUBVOLUME = "/";
          TIMELINE_CREATE = true;
          TIMELINE_CLEANUP = true;
        };
      };
    };
  };
}
