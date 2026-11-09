{ config, lib, ... }:
{
  resource = {
    # local NVMe scratch space for SABnzbd's incomplete downloads: writing,
    # repairing and unpacking them on the NAS over NFS is slow enough that
    # adding a job takes longer than Sonarr's 100s request timeout
    incus_storage_volume.apollo-scratch = {
      name = "apollo-scratch";
      pool = "fast";
      config.size = "400GiB";
    };

    incus_instance.apollo = {
      name = "apollo";
      image = "images:nixos/23.11";

      profiles = [
        "default"
        "nesting"
        "autostart"
      ];

      device = [
        {
          name = "media";
          type = "disk";
          properties = {
            source = "/media/unas/media";
            path = "/mnt/media";
          };
        }
        {
          name = "documents";
          type = "disk";
          properties = {
            source = "/media/unas/documents";
            path = "/mnt/documents";
          };
        }
        {
          name = "scratch";
          type = "disk";
          properties = {
            pool = "\${incus_storage_volume.apollo-scratch.pool}";
            source = "\${incus_storage_volume.apollo-scratch.name}";
            path = "/mnt/scratch";
          };
        }
      ];
    };

    cloudflare_record = {
      media = lib.cloudflare.makeDNSRecord "media";
      requests = lib.cloudflare.makeDNSRecord "requests";
      media-tools = lib.cloudflare.makeDNSRecord "media-tools";
      paperless = lib.cloudflare.makeDNSRecord "paperless";
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
