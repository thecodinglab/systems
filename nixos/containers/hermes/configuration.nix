{ config, modulesPath, ... }:
{
  system.stateVersion = "23.11";

  imports = [
    (modulesPath + "/virtualisation/lxc-container.nix")
    ./nginx.nix
  ];

  nixpkgs.hostPlatform = "x86_64-linux";

  custom = {
    isContainer = true;
    nginx = {
      enable = true;
      vhosts = {
        "hermes.thecodinglab.ch".locations."/".proxyPass = "http://localhost:7575/";
        "uptime.thecodinglab.ch".locations."/".proxyPass = "http://localhost:3001/";

        "teslamate.thecodinglab.ch" = {
          locations."/grafana".proxyPass = "http://172.16.0.92:3000";
          locations."/".proxyPass = "http://172.16.0.92:4000";
        };

        "home-assistant.thecodinglab.ch".locations."/".proxyPass = "http://172.16.0.92:8123";

        "media.thecodinglab.ch".locations."/".proxyPass = "http://172.16.0.233/";
        "requests.thecodinglab.ch".locations."/".proxyPass = "http://172.16.0.233/";
        "media-tools.thecodinglab.ch".locations."/".proxyPass = "http://172.16.0.233/";

        "iot.thecodinglab.ch".locations."/".proxyPass = "http://172.16.0.65:3000";
        "aphrodite.thecodinglab.ch".locations."/".proxyPass = "http://172.16.0.52/";
      };
    };
  };

  networking = {
    hostName = "hermes";
    firewall.allowedTCPPorts = [ 443 ];
  };

  services.uptime-kuma.enable = true;

  systemd.timers.podman-auto-update = {
    timerConfig = {
      Unit = "podman-auto-update.service";
      OnCalendar = "Mon 02:00";
      Persistent = true;
    };
    wantedBy = [ "timers.target" ];
  };

  virtualisation.oci-containers.containers = {
    homarr = {
      autoStart = true;
      image = "ghcr.io/ajnart/homarr:latest";

      labels = {
        "io.containers.autoupdate" = "registry";
      };

      ports = [ "127.0.0.1:7575:7575" ];
      volumes = [
        "homarr-config:/app/data/configs"
        "homarr-icons:/app/public/icons"
        "homarr-data:/data"
      ];
    };
  };

  sops.secrets.cloudflare = {
    sopsFile = ./secrets.yaml;
  };

  security.acme = {
    acceptTerms = true;
    defaults = {
      email = "fw@florian-walter.ch";
      dnsProvider = "cloudflare";
      credentialsFile = config.sops.secrets.cloudflare.path;
    };
  };
}
