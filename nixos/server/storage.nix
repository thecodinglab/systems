{ ... }:
{
  fileSystems."/media/unas/media" = {
    device = "192.168.32.185:/var/nfs/shared/Media";
    fsType = "nfs";
    options = [
      "x-systemd.automount"
      "x-systemd.idle-timeout=600"
      "noauto"
    ];
  };

  fileSystems."/media/unas/documents" = {
    device = "192.168.32.185:/var/nfs/shared/Documents";
    fsType = "nfs";
    options = [
      "x-systemd.automount"
      "x-systemd.idle-timeout=600"
      "noauto"
    ];
  };
}
