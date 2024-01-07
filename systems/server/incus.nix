{ config, pkgs, ... }: {
  services.lvm = {
    enable = true;
    boot.thin.enable = true;
  };

  security.apparmor = {
    enable = true;
  };

  # the base incus configuration is missing the lvm command line interface
  systemd.services.incus.path = [ config.services.lvm.package ];

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
          name = "docker";
          config = {
            "security.nesting" = "true";
            "security.syscalls.intercept.mknod" = "true";
            "security.syscalls.intercept.setxattr" = "true";
          };
        }
      ];
    };
  };
}
