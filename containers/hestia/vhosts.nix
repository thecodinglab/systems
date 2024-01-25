{
  "teslamate.thecodinglab.ch" = {
    locations."/grafana" = {
      proxyPass = "http://172.16.0.92:3000";
      recommendedProxySettings = true;
      proxyWebsockets = true;
    };

    locations."/" = {
      proxyPass = "http://172.16.0.92:4000";
      recommendedProxySettings = true;
      proxyWebsockets = true;
    };
  };

  "home-assistant.thecodinglab.ch" = {
    locations."/" = {
      proxyPass = "http://172.16.0.92:8123";
      recommendedProxySettings = true;
      proxyWebsockets = true;
    };
  };
}
