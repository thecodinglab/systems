# ssh client: keys come from the 1password agent, hosts shared by all
# machines live here, machine specific ones in hosts/<name>/home.nix
{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  root = hostname: {
    HostName = hostname;
    User = "root";
  };
  florian = hostname: {
    HostName = hostname;
    User = "florian";
  };
in
{
  options.custom.ssh = {
    enable = lib.mkEnableOption "enable ssh";
  };

  config = lib.mkIf config.custom.ssh.enable {
    programs.ssh = {
      enable = true;
      # the old defaults only restate what openssh does anyway
      enableDefaultConfig = false;

      # the hosts of the xcloud clusters, with their host keys
      includes = [ "${inputs.xcloud.packages.${pkgs.stdenv.hostPlatform.system}.ssh-config}" ];

      settings = {
        "*".IdentityAgent =
          if pkgs.stdenv.hostPlatform.isDarwin then
            ''"~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"''
          else
            "~/.1password/agent.sock";

        # workstations
        desktop = florian "192.168.48.10";
        macbook = florian "192.168.48.11";
        macmini = florian "192.168.48.124";

        server = {
          HostName = "192.168.1.113";
          User = "nix";
        };

        # incus containers on the server, see hosts/containers and infra/
        hermes = root "172.16.0.132";
        apollo = root "172.16.0.233";
        hestia = root "172.16.0.92";
        aphrodite = root "172.16.0.52";

        localhost.StrictHostKeyChecking = false;
      };
    };
  };
}
