{ ... }:
{
  resource.incus_instance.poseidon = {
    name = "poseidon";
    image = "images:nixos/23.11";

    profiles = [
      "default"
      "autostart"
    ];

    config = {
      "security.privileged" = "true";
    };

    device = [
      {
        name = "share";
        type = "disk";
        properties = {
          source = "share";
          pool = "data";
          path = "/mnt/share";
        };
      }
      {
        name = "timemachine";
        type = "disk";
        properties = {
          source = "timemachine";
          pool = "data";
          path = "/mnt/timemachine";
        };
      }
      {
        name = "media-library";
        type = "disk";
        properties = {
          source = "media-library";
          pool = "data";
          path = "/mnt/media-library";
        };
      }
    ];
  };

  resource.incus_storage_volume.share = {
    name = "share";
    pool = "data";
    type = "custom";

    config = {
      "block.filesystem" = "btrfs";
      "block.mount_options" = "noatime,discard";
      "snapshots.expiry" = "4w";
      "snapshots.schedule" = "@midnight";
    };
  };

  resource.incus_storage_volume.timemachine = {
    name = "timemachine";
    pool = "data";
    type = "custom";

    config = {
      "block.filesystem" = "btrfs";
      "block.mount_options" = "noatime,discard";
      "snapshots.expiry" = "4w";
      "snapshots.schedule" = "@midnight";
    };
  };
}
