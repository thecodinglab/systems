{ lib, ... }:
{
  resource = {
    incus_instance.hermes = {
      name = "hermes";
      image = "images:nixos/23.11";

      profiles = [
        "default"
        "nesting"
        "autostart"
      ];
    };

    cloudflare_record = {
      hermes = lib.cloudflare.makeDNSRecord "hermes";
      uptime = lib.cloudflare.makeDNSRecord "uptime";
    };

    cloudflare_access_application = {
      hermes = lib.cloudflare.makeDefaultApplication "hermes";
      uptime = lib.cloudflare.makeDefaultApplication "uptime";
    };

    cloudflare_access_policy = {
      hermes-policy-home = lib.cloudflare.makeHomeBypassAccessPolicy {
        application_id = "\${cloudflare_access_application.hermes.id}";
        precedence = "2";
      };
      hermes-policy-github = lib.cloudflare.makeGithubAllowancePolicy {
        application_id = "\${cloudflare_access_application.hermes.id}";
        precedence = "1";
      };

      uptime-policy-home = lib.cloudflare.makeHomeBypassAccessPolicy {
        application_id = "\${cloudflare_access_application.uptime.id}";
        precedence = "2";
      };
      uptime-policy-github = lib.cloudflare.makeGithubAllowancePolicy {
        application_id = "\${cloudflare_access_application.uptime.id}";
        precedence = "1";
      };
    };
  };
}
