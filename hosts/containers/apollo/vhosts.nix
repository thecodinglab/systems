let
  makeVHost = (vhost: {
    name = vhost;
    value = {
      locations."/" = {
        proxyPass = "http://172.16.0.233/";
        recommendedProxySettings = true;
        proxyWebsockets = true;
      };
    };
  });
in
builtins.listToAttrs [
  (makeVHost "media.thecodinglab.ch")
  (makeVHost "requests.thecodinglab.ch")
  (makeVHost "media-tools.thecodinglab.ch")
]
