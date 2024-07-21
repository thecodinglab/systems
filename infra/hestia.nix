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

    cloudflare_record = {
      teslamate = lib.cloudflare.makeDNSRecord "teslamate";
      home-assistant = lib.cloudflare.makeDNSRecord "home-assistant";
    };

    cloudflare_access_application = {
      teslamate = lib.cloudflare.makeDefaultApplication "teslamate";
      home-assistant = lib.cloudflare.makeDefaultApplication "home-assistant";
    };

    cloudflare_access_policy = {
      teslamate-policy-home = lib.cloudflare.makeHomeBypassAccessPolicy {
        application_id = "\${cloudflare_access_application.teslamate.id}";
        precedence = "2";
      };
      teslamate-policy-github = lib.cloudflare.makeGithubAllowancePolicy {
        application_id = "\${cloudflare_access_application.teslamate.id}";
        precedence = "1";
      };

      home-assistant-policy-home = lib.cloudflare.makeHomeBypassAccessPolicy {
        application_id = "\${cloudflare_access_application.home-assistant.id}";
        precedence = "2";
      };
      home-assistant-policy-github = lib.cloudflare.makeGithubAllowancePolicy {
        application_id = "\${cloudflare_access_application.home-assistant.id}";
        precedence = "1";
      };
    };
  };
}
