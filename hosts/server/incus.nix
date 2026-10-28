{ ... }:
{
  services.lvm = {
    enable = true;
    # Despite the name, this also configures thin_check for the running system.
    boot.thin.enable = true;
  };

  # vg0 isn't needed to boot. Activating it in the initrd races switch-root,
  # which kills thin_check and leaves the thin pool half-activated.
  boot.initrd.services.lvm.enable = false;

  virtualisation.incus = {
    enable = true;

    preseed = {
      config = {
        "core.https_address" = "192.168.1.113:8443";
      };

      storage_pools = [
        {
          name = "data";
          driver = "lvm";
          config = {
            source = "vg0";
            "lvm.thinpool_name" = "LXDThinPool";
            "lvm.vg_name" = "vg0";

            "volume.block.filesystem" = "btrfs";
            "volume.snapshots.schedule" = "@midnight";
            "volume.snapshots.expiry" = "4w";
          };
        }
      ];

      profiles = [
        {
          name = "default";
          config = {
            "boot.autostart" = "false";
            "snapshots.schedule" = "@daily";
            "snapshots.expiry" = "4w";

            # required for the nix sandbox
            "security.nesting" = "true";
          };
          devices = {
            root = {
              path = "/";
              pool = "data";
              type = "disk";
            };
            eth0 = {
              name = "eth0";
              nictype = "bridged";
              parent = "br0";
              type = "nic";
            };
          };
        }
        {
          name = "autostart";
          config = {
            "boot.autostart" = "true";
          };
        }
        {
          name = "nesting";
          config = {
            "security.syscalls.intercept.mknod" = "true";
            "security.syscalls.intercept.setxattr" = "true";
          };
        }
      ];
    };
  };
}
