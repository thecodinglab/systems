{ ... }:
let
  uid = 1000;
  gid = 1000;

  unasMediaMountpoint = "/mnt/media";
  unasDocumentsMountpoint = "/mnt/documents";

  # local NVMe volume, see infra/apollo.nix
  scratchMountpoint = "/mnt/scratch";
in
{
  system.stateVersion = "23.11";

  imports = [ ../common.nix ];

  networking.hostName = "apollo";

  custom.proxy.enable = true;

  users = {
    users.media = {
      isSystemUser = true;
      group = "media";
      home = "/var/empty";
      inherit uid;
    };

    groups.media = {
      inherit gid;
    };
  };

  systemd.tmpfiles.rules = [
    "d ${scratchMountpoint}/incomplete 0755 media media -"
  ];

  services = {
    nginx = {
      enable = true;

      virtualHosts = {
        "media.thecodinglab.ch".locations."/" = {
          proxyPass = "http://localhost:32400/";
          proxyWebsockets = true;
        };

        "requests.thecodinglab.ch".locations."/" = {
          proxyPass = "http://localhost:40002";
          proxyWebsockets = true;
        };

        "media-tools.thecodinglab.ch" = {
          locations."/sabnzbd" = {
            proxyPass = "http://localhost:40001/sabnzbd";
            proxyWebsockets = true;
          };
          locations."/tautulli" = {
            proxyPass = "http://localhost:8181";
            proxyWebsockets = true;
          };

          locations."/english/radarr" = {
            proxyPass = "http://localhost:41001";
            proxyWebsockets = true;
          };
          locations."/english/sonarr" = {
            proxyPass = "http://localhost:41002";
            proxyWebsockets = true;
          };

          locations."/german/radarr" = {
            proxyPass = "http://localhost:42001";
            proxyWebsockets = true;
          };
          locations."/german/sonarr" = {
            proxyPass = "http://localhost:42002";
            proxyWebsockets = true;
          };
          locations."/german/readarr" = {
            proxyPass = "http://localhost:42003";
            proxyWebsockets = true;
          };
        };

        "paperless.thecodinglab.ch".forceSSL = false;
      };
    };

    plex = {
      enable = true;
      user = "media";
      group = "media";
    };

    tautulli = {
      enable = true;
      user = "media";
      group = "media";
    };

    paperless = {
      enable = true;
      domain = "paperless.thecodinglab.ch";
      mediaDir = "${unasDocumentsMountpoint}/";

      configureNginx = true;
      configureTika = true;
      database.createLocally = true;
    };
  };

  # the containers talk to each other by name (sabnzbd:8080, sonarr-german:8989,
  # ...): the published ports are bound to the host's loopback only, which is
  # not reachable from inside the containers
  virtualisation.podman.defaultNetwork.settings.dns_enabled = true;
  # podman 6 reads network definitions from its graphroot
  # (/var/lib/containers/storage/networks) by default and ignores the
  # podman.json the NixOS module generates in /etc/containers/networks
  virtualisation.containers.containersConf.settings.network.network_config_dir =
    "/etc/containers/networks";
  # plex runs on the host, seerr reaches it at host.containers.internal:32400
  networking.firewall.interfaces."podman+".allowedTCPPorts = [ 32400 ];

  # the media share is mounted as a whole at /data in every container that
  # moves files between downloads and the library, so that importing a
  # download is a rename on the NAS instead of a copy over NFS (separate bind
  # mounts for downloads and library make every move cross-device); the
  # libraries live at /data/{Movies,TV}/<Language>
  virtualisation.oci-containers.containers =
    let
      mediaVolume = "${unasMediaMountpoint}:/data";

      makeLinuxserverContainer = (
        {
          name,
          image,
          port,
          volumes,
        }:
        {
          autoStart = true;
          image = "lscr.io/linuxserver/${image}";

          labels = {
            "io.containers.autoupdate" = "registry";
          };

          environment = {
            TZ = "Europe/Zurich";
            PUID = toString uid;
            PGID = toString gid;
          };

          ports = [ "127.0.0.1:${toString port.src}:${toString port.dst}" ];

          volumes = [ "${name}-config:/config" ] ++ volumes;
        }
      );

      makeRadarrContainer = (
        {
          lang,
          port,
        }:
        makeLinuxserverContainer {
          name = "radarr-${lang}";
          image = "radarr:latest";
          port = {
            src = port;
            dst = 7878;
          };
          volumes = [ mediaVolume ];
        }
      );

      makeSonarrContainer = (
        {
          lang,
          port,
        }:
        makeLinuxserverContainer {
          name = "sonarr-${lang}";
          image = "sonarr:latest";
          port = {
            src = port;
            dst = 8989;
          };
          volumes = [ mediaVolume ];
        }
      );

      makeReadarrContainer = (
        {
          lang,
          port,
          mountpoint,
        }:
        makeLinuxserverContainer {
          name = "readarr-${lang}";
          image = "readarr:develop";
          port = {
            src = port;
            dst = 8787;
          };
          # the library stays at /books, readarr stores absolute paths for
          # every book file
          volumes = [
            mediaVolume
            "${mountpoint}:/books"
          ];
        }
      );
    in
    {
      # incomplete downloads go to local NVMe (download_dir = /incomplete),
      # finished ones to the NAS (complete_dir = /data/Downloads/complete)
      sabnzbd = makeLinuxserverContainer {
        name = "sabnzbd";
        image = "sabnzbd:latest";
        port = {
          src = 40001;
          dst = 8080;
        };
        volumes = [
          mediaVolume
          "${scratchMountpoint}/incomplete:/incomplete"
        ];
      };

      # successor of overseerr, which migrated its config on first start (the
      # old overseerr-config volume is kept as a backup); the official image
      # runs as uid 1000 and needs an init process
      seerr = {
        autoStart = true;
        image = "ghcr.io/seerr-team/seerr:v3";

        labels = {
          "io.containers.autoupdate" = "registry";
        };

        environment = {
          TZ = "Europe/Zurich";
        };

        extraOptions = [ "--init" ];

        ports = [ "127.0.0.1:40002:5055" ];

        volumes = [ "seerr-config:/app/config" ];
      };

      radarr-english = makeRadarrContainer {
        lang = "english";
        port = 41001;
      };
      sonarr-english = makeSonarrContainer {
        lang = "english";
        port = 41002;
      };

      radarr-german = makeRadarrContainer {
        lang = "german";
        port = 42001;
      };
      sonarr-german = makeSonarrContainer {
        lang = "german";
        port = 42002;
      };
      readarr-german = makeReadarrContainer {
        lang = "german";
        port = 42003;
        mountpoint = "${unasMediaMountpoint}/Books/German";
      };
    };
}
