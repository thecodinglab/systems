{ lib, ... }:
{
  terraform.required_providers = {
    incus.source = "lxc/incus";
    cloudflare.source = "cloudflare/cloudflare";
    sops.source = "carlpett/sops";
  };

  provider = {
    incus = { };

    cloudflare = {
      api_token = lib.cloudflare.api_token;
    };

    sops = { };
  };

  data.sops_file.secrets = {
    source_file = toString ./secrets.yaml;
  };
}
