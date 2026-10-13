# nginx in front of the services of a host that hermes forwards requests to:
# the services only listen on localhost and nginx only accepts requests from
# hermes, which handles tls and authentication for everyone else
{ config, lib, ... }:
let
  cfg = config.custom.proxy;
in
{
  options.custom.proxy = {
    enable = lib.mkEnableOption "the nginx proxy behind hermes";

    allowedAddresses = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      # the container network, hermes included
      default = [ "172.16.0.0/24" ];
      description = "Addresses and networks allowed to talk to the proxy besides localhost.";
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [ 80 ];

    services.nginx = {
      enable = true;

      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;

      # same limits as hermes, everything it accepts has to get through here too
      clientMaxBodySize = "4G";
      proxyTimeout = "1h";

      # http level, so it also covers vhosts added by other modules (e.g.
      # services.paperless.configureNginx)
      commonHttpConfig = ''
        allow 127.0.0.0/8;
        allow ::1;
        ${lib.concatMapStrings (addr: "allow ${addr};\n") cfg.allowedAddresses}
        deny all;
      '';

      virtualHosts.default = {
        default = true;
        locations."/".return = "404";
      };
    };
  };
}
