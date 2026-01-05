{ config, lib, ... }:
{
  resource = {
    incus_instance.apollo = {
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

      device = [
        {
          name = "media";
          type = "disk";
          properties = {
            source = "/media/unas/media";
            path = "/mnt";
          };
        }
      ];
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
