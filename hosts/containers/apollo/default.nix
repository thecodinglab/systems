{
  # Apollo: god of music, arts, knowledge

  infrastructure = ({ lib, ... }: rec {
    resource = {
      incus_instance.apollo = {
        depends_on = [ "incus_volume.media" ];

        name = "apollo";
        image = "images:nixos/23.11";

        profiles = [
          "default"
          "nesting"
          "autostart"
        ];

        limits = {
          cpu = 16;
        };

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

      incus_volume.media = {
        name = "media-library";
        pool = "data";
        type = "custom";

        config = {
          "block.filesystem" = "btrfs";
          "block.mount_options" = "noatime,discard";
          "snapshots.expiry" = "4w";
          "snapshots.schedule" = "@midnight";
          "security.shifted" = "true";
        };
      };

      cloudflare_record = {
        media = lib.cloudflare.makeDNSRecord "media";
        requests = lib.cloudflare.makeDNSRecord "requests";
        media-tools = lib.cloudflare.makeDNSRecord "media-tools";
      };

      cloudflare_access_application.media-tools =
        lib.cloudflare.makeDefaultApplication "media-tools";

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
  });

  system = ({ ... }:
    let
      uid = 1000;
      gid = 1000;
    in
    {
      networking.hostName = "apollo";

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
            locations."/tautulli" = {
              proxyPass = "http://localhost:8181";
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

      services.tautulli = {
        enable = true;
        user = "media";
        group = "media";
      };

      systemd.timers.podman-auto-update = {
        timerConfig = {
          Unit = "podman-auto-update.service";
          OnCalendar = "Mon 02:00";
          Persistent = true;
        };
        wantedBy = [ "timers.target" ];
      };

      virtualisation.oci-containers.containers =
        let
          makeLinuxserverContainer = ({ name, image, port, volumes }: {
            autoStart = true;
            image = "docker.io/linuxserver/${image}";

            labels = {
              "io.containers.autoupdate" = "registry";
            };

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
