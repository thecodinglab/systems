{ config, lib, ... }:
{
  options.custom.vpn = {
    enable = lib.mkEnableOption "enable vpn";
  };

  config = lib.mkIf config.custom.audio.enable {
    sops = {
      secrets = {
        proton-username.sopsFile = ./secrets.yaml;
        proton-password.sopsFile = ./secrets.yaml;
      };

      templates.proton-openvpn-credentials.content = ''
        ${config.sops.placeholder.proton-username}
        ${config.sops.placeholder.proton-password}
      '';
    };

    services.openvpn.servers = {
      proton-switzerland = {
        autoStart = false;
        config = ''
          config ${./ch.protonvpn.udp.ovpn} 
          auth-user-pass ${config.sops.templates.proton-openvpn-credentials.path}
        '';
      };
    };
  };
}
