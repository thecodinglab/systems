{ config, ... }:
{
  sops.secrets.unas_credentials = { };

  fileSystems."/media/unas/personal" = {
    device = "//192.168.32.185/Personal-Drive";
    fsType = "cifs";
    options = [
      "credentials=${config.sops.secrets.unas_credentials.path}"
      "uid=florian"
      "gid=users"

      "x-systemd.automount"
      "x-systemd.idle-timeout=600"
      "noauto"
    ];
  };

  fileSystems."/media/unas/family" = {
    device = "192.168.32.185:/var/nfs/shared/Familie";
    fsType = "nfs";
    options = [
      "x-systemd.automount"
      "x-systemd.idle-timeout=600"
      "noauto"
    ];
  };

  fileSystems."/media/unas/media" = {
    device = "192.168.32.185:/var/nfs/shared/Media";
    fsType = "nfs";
    options = [
      "x-systemd.automount"
      "x-systemd.idle-timeout=600"
      "noauto"
    ];
  };

  fileSystems."/media/unas/backups" = {
    device = "192.168.32.185:/var/nfs/shared/Backups";
    fsType = "nfs";
    options = [
      "x-systemd.automount"
      "x-systemd.idle-timeout=600"
      "noauto"
    ];
  };
}
