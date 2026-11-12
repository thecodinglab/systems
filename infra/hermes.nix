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
      home-assistant = lib.cloudflare.makeDNSRecord "home-assistant";
    };

    cloudflare_access_application = {
      hermes = lib.cloudflare.makeDefaultApplication "hermes";
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
    };
  };
}
