{
  # Apollo: god of music, arts, knowledge

  infrastructure = ({ lib, ... }: rec {
    resource.incus_instance.apollo = {
      depends_on = [ "incus_volume.media" ];

      name = "apollo";
      image = "images:nixos/23.11";

      profiles = [
        "default"
        "nesting"
        "autostart"
      ];

      device = {
        name = "library";
        type = "disk";
        properties = {
          source = resource.incus_volume.media.name;
          pool = resource.incus_volume.media.pool;
          path = "/media";
        };
      };
    };

    resource.incus_volume.media = {
      name = "media-library";
      pool = "data";
      type = "custom";

      config = {
        "block.filesystem" = "btrfs";
        "block.mount_options" = "discard";
        "snapshots.expiry" = "4w";
        "snapshots.schedule" = "@midnight";
        "security.shifted" = "true";
      };
    };

    resource.cloudflare_record = {
      media = lib.makeCloudflareDNSRecord "media";
      requests = lib.makeCloudflareDNSRecord "requests";
      media-tools = lib.makeCloudflareDNSRecord "media-tools";
    };
  });

  system = ({ ... }:
    let
      uid = 1000;
      gid = 1000;
    in
    {
      networking = {
        hostName = "apollo";
        firewall = {
          allowedTCPPorts = [ 80 32400 8324 32469 ];
          allowedUDPPorts = [ 1900 5353 32410 32412 32413 32414 ];
        };
      };

      services.nginx = {
        enable = true;

        virtualHosts = {
          default = {
            default = true;
            locations."/".return = "404";
          };

          "media.thecodinglab.ch".locations."/" = {
            proxyPass = "http://localhost:32400/";
            recommendedProxySettings = true;
            proxyWebsockets = true;
          };

          "requests.thecodinglab.ch".locations."/" = {
            proxyPass = "http://localhost:40002";
            recommendedProxySettings = true;
            proxyWebsockets = true;
          };

          "media-tools.thecodinglab.ch" = {
            locations."/sabnzbd" = {
              proxyPass = "http://localhost:40001/sabnzbd";
              recommendedProxySettings = true;
              proxyWebsockets = true;
            };

            locations."/english/radarr" = {
              proxyPass = "http://localhost:41001";
              recommendedProxySettings = true;
              proxyWebsockets = true;
            };
            locations."/english/sonarr" = {
              proxyPass = "http://localhost:41002";
              recommendedProxySettings = true;
              proxyWebsockets = true;
            };

            locations."/german/radarr" = {
              proxyPass = "http://localhost:42001";
              recommendedProxySettings = true;
              proxyWebsockets = true;
            };
            locations."/german/sonarr" = {
              proxyPass = "http://localhost:42002";
              recommendedProxySettings = true;
              proxyWebsockets = true;
            };
          };
        };
      };

      users = {
        users.media = {
          isSystemUser = true;
          group = "media";
          inherit uid;
        };

        groups.media = { inherit gid; };
      };

      services.plex = {
        enable = true;
        user = "media";
        group = "media";
      };

      virtualisation.oci-containers.containers =
        let
          makeLinuxserverContainer = ({ name, image, port, volumes }: {
            autoStart = true;
            image = "linuxserver/${image}";

            environment = {
              TZ = "Europe/Zurich";
              PUID = toString uid;
              PGID = toString gid;
            };

            ports = [
              "${toString port.src}:${toString port.dst}"
            ];

            volumes = [
              "${name}-config:/config"
            ] ++ volumes;
          });

          makeRadarrContainer = ({ lang, port }: makeLinuxserverContainer {
            name = "radarr-${lang}";
            image = "radarr:latest";
            port = { src = port; dst = 7878; };
            volumes = [
              "/media/downloads:/downloads"
              "/media/libraries/movies/${lang}:/movies"
            ];
          });

          makeSonarrContainer = ({ lang, port }: makeLinuxserverContainer {
            name = "sonarr-${lang}";
            image = "sonarr:latest";
            port = { src = port; dst = 8989; };
            volumes = [
              "/media/downloads:/downloads"
              "/media/libraries/series/${lang}:/tv"
            ];
          });
        in
        {
          sabnzbd = makeLinuxserverContainer {
            name = "sabnzbd";
            image = "sabnzbd:latest";
            port = { src = 40001; dst = 8080; };
            volumes = [
              "/media/downloads:/downloads"
            ];
          };

          overseerr = makeLinuxserverContainer {
            name = "overseerr";
            image = "overseerr:latest";
            port = { src = 40002; dst = 5055; };
            volumes = [ ];
          };

          radarr-english = makeRadarrContainer { lang = "english"; port = 41001; };
          sonarr-english = makeSonarrContainer { lang = "english"; port = 41002; };

          radarr-german = makeRadarrContainer { lang = "german"; port = 42001; };
          sonarr-german = makeSonarrContainer { lang = "german"; port = 42002; };
        };
    });
}
