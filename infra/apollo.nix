{ config, lib, ... }:
{
  resource = {
    incus_instance.apollo = {
      depends_on = [ "incus_storage_volume.media" ];

      name = "apollo";
      image = "images:nixos/23.11";

      profiles = [
        "default"
        "nesting"
        "autostart"
      ];

      limits = {
        cpu = 18;
      };

      device = {
        name = "library";
        type = "disk";
        properties = {
          source = config.resource.incus_storage_volume.media.name;
          pool = config.resource.incus_storage_volume.media.pool;
          path = "/media";
        };
      };
    };

    incus_storage_volume.media = {
      name = "media-library";
      pool = "data";
      type = "custom";

      config = {
        "block.filesystem" = "btrfs";
        "block.mount_options" = "noatime,discard";
        "snapshots.expiry" = "4w";
        "snapshots.schedule" = "@midnight";
        "security.shifted" = "true";
      };
    };

    cloudflare_record = {
      media = lib.cloudflare.makeDNSRecord "media";
      requests = lib.cloudflare.makeDNSRecord "requests";
      media-tools = lib.cloudflare.makeDNSRecord "media-tools";
    };

    cloudflare_access_application.media-tools = lib.cloudflare.makeDefaultApplication "media-tools";

    cloudflare_access_policy = {
      media-tools-policy-home = lib.cloudflare.makeHomeBypassAccessPolicy {
        application_id = "\${cloudflare_access_application.media-tools.id}";
        precedence = "2";
      };
      media-tools-policy-github = lib.cloudflare.makeGithubAllowancePolicy {
        application_id = "\${cloudflare_access_application.media-tools.id}";
        precedence = "1";
      };
    };
  };
}
