args@{ ... }:
let
  config = args.hermes or { };

  baseVhosts = {
    "hermes.thecodinglab.ch" = {
      locations."/" = {
        proxyPass = "http://localhost:7575/";
      };
    };
  };

  vhosts = baseVhosts // (config.vhosts or { });
in
{
  services.nginx = {
    enable = true;

    virtualHosts = vhosts;
  };

  virtualisation.oci-containers = {
    backend = "docker";

    containers = {
      homarr = {
        autoStart = true;
        image = "ghcr.io/ajnart/homarr:latest";
        ports = [
          "127.0.0.1:7575:7575"
        ];
        volumes = [
          "homarr-config:/app/data/configs"
          "homarr-icons:/app/public/icons"
          "homarr-data:/data"
        ];
      };
    };
  };
}
