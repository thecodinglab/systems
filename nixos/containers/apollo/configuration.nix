{ config, modulesPath, ... }:
let
  uid = 1000;
  gid = 1000;
in
{
  system.stateVersion = "23.11";

  imports = [ (modulesPath + "/virtualisation/lxc-container.nix") ];

  nixpkgs.hostPlatform = "x86_64-linux";

  custom = {
    isContainer = true;
    unfree = [ "plexmediaserver" ];
  };

  networking = {
    hostName = "apollo";
    firewall.allowedTCPPorts = [ 80 ];
  };

  users = {
    users.media = {
      isSystemUser = true;
      group = "media";
      home = "/home/media";
      inherit uid;
    };

    groups.media = {
      inherit gid;
    };
  };

  sops.secrets.kavita = {
    sopsFile = ./secrets.yaml;
  };

  services = {
    nginx = {
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
          locations."/german/readarr" = {
            proxyPass = "http://localhost:42003";
            recommendedProxySettings = true;
            proxyWebsockets = true;
          };
          locations."/kavita" = {
            proxyPass = "http://localhost:5000";
            recommendedProxySettings = true;
            proxyWebsockets = true;
            extraConfig = ''
              sub_filter '<base href="/">'  '<base href="/kavita/">';
              sub_filter_once off;
            '';
          };
        };
      };
    };

    plex = {
      enable = true;
      openFirewall = true;
      user = "media";
      group = "media";
    };

    tautulli = {
      enable = true;
      user = "media";
      group = "media";
    };

    kavita = {
      enable = true;
      user = "kavita";
      tokenKeyFile = config.sops.secrets.kavita.path;
      settings = {
        AllowStatCollection = false;
        BaseUrl = "/kavita/";
      };
    };
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

          ports = [ "${toString port.src}:${toString port.dst}" ];

          volumes = [ "${name}-config:/config" ] ++ volumes;
        }
      );

      makeRadarrContainer = (
        { lang, port }:
        makeLinuxserverContainer {
          name = "radarr-${lang}";
          image = "radarr:latest";
          port = {
            src = port;
            dst = 7878;
          };
          volumes = [
            "/media/downloads:/downloads"
            "/media/libraries/movies/${lang}:/movies"
          ];
        }
      );

      makeSonarrContainer = (
        { lang, port }:
        makeLinuxserverContainer {
          name = "sonarr-${lang}";
          image = "sonarr:latest";
          port = {
            src = port;
            dst = 8989;
          };
          volumes = [
            "/media/downloads:/downloads"
            "/media/libraries/series/${lang}:/tv"
          ];
        }
      );

      makeReadarrContainer = (
        { lang, port }:
        makeLinuxserverContainer {
          name = "readarr-${lang}";
          image = "readarr:develop";
          port = {
            src = port;
            dst = 8787;
          };
          volumes = [
            "/media/downloads:/downloads"
            "/media/libraries/books/${lang}:/books"
          ];
        }
      );
    in
    {
      sabnzbd = makeLinuxserverContainer {
        name = "sabnzbd";
        image = "sabnzbd:latest";
        port = {
          src = 40001;
          dst = 8080;
        };
        volumes = [ "/media/downloads:/downloads" ];
      };

      overseerr = makeLinuxserverContainer {
        name = "overseerr";
        image = "overseerr:latest";
        port = {
          src = 40002;
          dst = 5055;
        };
        volumes = [ ];
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
      };
    };
}
