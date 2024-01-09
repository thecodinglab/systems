{ tofu, ... }: rec {
  # Apollo: god of music, arts, knowledge
  resource.incus_instance.apollo = {
    depends_on = [ "incus_volume.media" ];

    name = "apollo";
    image = "images:nixos/23.11";

    profiles = [
      "default"
      "nesting"
      "autostart"
    ];

    device = {
      name = "library";
      type = "disk";
      properties = {
        source = resource.incus_volume.media.name;
        pool = resource.incus_volume.media.pool;
        path = "/media";
      };
    };
  };

  resource.incus_volume.media = {
    name = "media-library";
    pool = "data";
    type = "custom";

    config = {
      "block.filesystem" = "btrfs";
      "block.mount_options" = "discard";
      "snapshots.expiry" = "4w";
      "snapshots.schedule" = "@midnight";
    };
  };

  resource.cloudflare_record = {
    media = tofu.makeCloudflareDNSRecord "media";
    requests = tofu.makeCloudflareDNSRecord "requests";
    media-tools = tofu.makeCloudflareDNSRecord "media-tools";
  };
}
