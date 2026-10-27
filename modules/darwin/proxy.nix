# nginx in front of the services of a host that hermes forwards requests to:
# the services only listen on localhost and nginx only accepts requests from
# hermes, which handles tls and authentication for everyone else (counterpart
# of modules/nixos/proxy.nix, nix-darwin has no nginx module)
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.custom.proxy;
  inherit (lib) mkOption types;

  location = types.submodule {
    options.proxyPass = mkOption {
      type = types.str;
      example = "http://127.0.0.1:8080";
      description = "Upstream the requests are passed to (nginx proxy_pass).";
    };
  };

  vhost = types.submodule {
    options.locations = mkOption {
      type = types.attrsOf location;
      default = { };
      description = "Locations of the virtual host, by path.";
    };
  };

  mkVhost = name: vhost: ''
    server {
      listen ${toString cfg.port};
      listen [::]:${toString cfg.port};
      server_name ${name};
      ${lib.concatStrings (
        lib.mapAttrsToList (path: location: ''
          location ${path} {
            proxy_pass ${location.proxyPass};
          }
        '') vhost.locations
      )}
    }
  '';

  # mirrors the recommended*Settings of the nixos module
  configFile = pkgs.writeText "nginx.conf" ''
    user nobody nobody;
    worker_processes auto;
    pid /var/run/nginx.pid;
    daemon off;
    error_log stderr;

    events {}

    http {
      access_log off;

      sendfile on;
      tcp_nopush on;
      tcp_nodelay on;
      keepalive_timeout 65;

      gzip on;
      gzip_proxied any;
      gzip_vary on;

      # same limits as hermes, everything it accepts has to get through here too
      client_max_body_size 4G;

      proxy_http_version 1.1;
      proxy_connect_timeout 60s;
      proxy_send_timeout 1h;
      proxy_read_timeout 1h;
      proxy_set_header Host $host;
      proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header X-Forwarded-Proto $scheme;
      proxy_set_header X-Forwarded-Host $host;
      proxy_set_header X-Forwarded-Server $hostname;

      # websockets; set here as a location setting any proxy_set_header would
      # no longer inherit the ones above
      proxy_set_header Upgrade $http_upgrade;
      proxy_set_header Connection $connection_upgrade;

      map $http_upgrade $connection_upgrade {
        default upgrade;
        ''' close;
      }

      allow 127.0.0.0/8;
      allow ::1;
      ${lib.concatMapStrings (addr: "allow ${addr};\n") cfg.allowedAddresses}
      deny all;

      server {
        listen ${toString cfg.port} default_server;
        listen [::]:${toString cfg.port} default_server;
        return 404;
      }

      ${lib.concatStrings (lib.mapAttrsToList mkVhost cfg.vhosts)}
    }
  '';
in
{
  options.custom.proxy = {
    enable = lib.mkEnableOption "the nginx proxy behind hermes";

    package = lib.mkPackageOption pkgs "nginx" { };

    port = mkOption {
      type = types.port;
      default = 80;
      description = "Port nginx listens on.";
    };

    allowedAddresses = mkOption {
      type = types.listOf types.str;
      # the container network, hermes included
      default = [ "172.16.0.0/24" ];
      description = "Addresses and networks allowed to talk to the proxy besides localhost.";
    };

    vhosts = mkOption {
      type = types.attrsOf vhost;
      default = { };
      example = lib.literalExpression ''
        {
          "kakeibo.ch".locations."/".proxyPass = "http://127.0.0.1:8080";
        }
      '';
      description = "Virtual hosts, by server name; websocket upgrades are always passed on.";
    };
  };

  config = lib.mkIf cfg.enable {
    launchd.daemons.nginx.command = lib.escapeShellArgs [
      (lib.getExe cfg.package)
      "-c"
      "${configFile}"
      "-e"
      "stderr"
    ];
    launchd.daemons.nginx.serviceConfig = {
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/var/log/nginx.log";
      StandardErrorPath = "/var/log/nginx.log";
    };
  };
}
