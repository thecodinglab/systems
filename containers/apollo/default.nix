{ ... }:
let
  uid = 1000;
  gid = 1000;
in
{
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
      };

      "media-tools.thecodinglab.ch" = {
        locations."/sabnzbd" = {
          proxyPass = "http://localhost:40001/";
          recommendedProxySettings = true;
        };

        locations."/english/radarr" = {
          proxyPass = "http://localhost:41001/";
          recommendedProxySettings = true;
        };
        locations."/english/sonarr" = {
          proxyPass = "http://localhost:41002/";
          recommendedProxySettings = true;
        };

        locations."/german/radarr" = {
          proxyPass = "http://localhost:42001/";
          recommendedProxySettings = true;
        };
        locations."/german/sonarr" = {
          proxyPass = "http://localhost:42002/";
          recommendedProxySettings = true;
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
      makeLinuxserverContainer = ({ name, image, port, volumes }:
        let
          res = {
            autoStart = true;
            image = "linuxserver/${image}";

            environment = {
              TZ = "Europe/Zurich";
              PUID = toString uid;
              PGID = toString gid;
            };

            ports = [
              "127.0.0.1:${toString port.src}:${toString port.dst}"
            ];

            volumes = [
              "${name}-config:/config"
            ] ++ volumes;
          };
        in
        builtins.trace (builtins.toJSON res) res);

      makeRadarrContainer = ({ lang, port }: makeLinuxserverContainer {
        name = "radarr-${lang}";
        image = "radarr:latest";
        port = { src = port; dst = 7878; };
        volumes = [
          "/media/downloads/complete:/downloads"
          "/media/libraries/movies/${lang}:/movies"
        ];
      });

      makeSonarrContainer = ({ lang, port }: makeLinuxserverContainer {
        name = "sonarr-${lang}";
        image = "sonarr:latest";
        port = { src = port; dst = 8989; };
        volumes = [
          "/media/downloads/complete:/downloads"
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
          "/media/downloads/complete:/downloads"
          "/media/downloads/incomplete:/incomplete-downloads"
        ];
      };

      radarr-english = makeRadarrContainer { lang = "english"; port = 41001; };
      sonarr-english = makeSonarrContainer { lang = "english"; port = 41002; };

      radarr-german = makeRadarrContainer { lang = "german"; port = 42001; };
      sonarr-german = makeSonarrContainer { lang = "german"; port = 42002; };
    };
}
