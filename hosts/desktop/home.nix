{ config, pkgs, ... }:
{
  imports = [
    ../../home/florian
    ../../home/florian/linux.nix
    ../../home/florian/dev.nix
    ../../home/florian/writing.nix
  ];

  # the other machines, by ssh alias (F12): a permanent connection to the
  # mini, the macbook dialled on demand
  programs.devtools.machines = {
    macmini.connect = true;
    macbook = { };
  };

  # ssh keys come from the machine you log in from, see the ssh module: from
  # the macbook this one may well be locked
  custom.ssh.forwardedAgents.enable = true;
  # and so do the keys of the devtools panes, which the server starts
  programs.devtools.server.environment.SSH_AUTH_SOCK = config.custom.ssh.forwardedAgents.socket;

  # btop reads the RTX 3080 through libnvidia-ml, which it only finds with
  # the driver runpath that cudaSupport adds; without it, btop shows only the
  # idle iGPU
  programs.btop.package = pkgs.btop.override { cudaSupport = true; };

  # AirPods Max, toggled with Super+B
  custom.hyprland.headphones = "90:62:3F:9B:23:F7";

  # off by default: enable once the user_florian age key is on this machine
  # and the secret is migrated, see home/florian/writing.nix
  # custom.writing.languageTool.enable = true;
}
