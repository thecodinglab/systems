{ lib, ... }:
{
  resource = {
    incus_instance.hestia = {
      name = "hestia";
      image = "images:nixos/23.11";

      profiles = [
        "default"
        "nesting"
        "autostart"
      ];
    };

    cloudflare_record.teslamate = lib.cloudflare.makeDNSRecord "teslamate";

    cloudflare_access_application.teslamate = lib.cloudflare.makeDefaultApplication "teslamate";

    cloudflare_access_policy = {
      teslamate-policy-home = lib.cloudflare.makeHomeBypassAccessPolicy {
        application_id = "\${cloudflare_access_application.teslamate.id}";
        precedence = "2";
      };
      teslamate-policy-github = lib.cloudflare.makeGithubAllowancePolicy {
        application_id = "\${cloudflare_access_application.teslamate.id}";
        precedence = "1";
      };
    };
  };
}
