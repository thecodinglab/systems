{
  config,
  lib,
  modulesPath,
  outputs,
  pkgs,
  ...
}:
{
  imports = [ (modulesPath + "/virtualisation/lxc-container.nix") ];

  nixpkgs.hostPlatform = "x86_64-linux";

  networking.nftables.enable = false;

  environment.systemPackages = [ pkgs.neovim-minimal ];

  users.users.root = {
    shell = pkgs.zsh;

    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKrk+aYPC9+XPBzYI6uuxRbczvimV1Brclkic873p0Uv"
    ];
  };

  home-manager.users.root =
    { lib, ... }:
    {
      home.stateVersion = "23.11";

      imports = lib.attrValues outputs.homeManagerModules;

      custom = {
        fzf.enable = true;
        zsh = {
          enable = true;
          hostname = true;
        };
      };

      programs.btop.enable = true;
    };

  # podman decides where to bind-mount the container network namespaces with
  # unshare.IsRootless(), which also returns true when the process has no full
  # uid mapping, i.e. always inside an unprivileged incus container. it then
  # uses $XDG_RUNTIME_DIR (or /run/user/0) instead of /run/netns. /run/user/0
  # is mounted and unmounted by systemd-logind with every root login (such as
  # nixos-rebuild --target-host), so the netns paths vanish, netavark cannot
  # tear down the port forwarding rules of stopped containers, and the stale
  # DNAT rules shadow the newly created containers. pin the directory to a
  # location that survives logins.
  systemd.tmpfiles.rules = [ "d /run/containers 0700 root root -" ];
  systemd.services = lib.mapAttrs' (
    name: _:
    lib.nameValuePair "podman-${name}" {
      environment.XDG_RUNTIME_DIR = "/run/containers";
    }
  ) config.virtualisation.oci-containers.containers;

  systemd.timers.podman-auto-update = {
    timerConfig = {
      Unit = "podman-auto-update.service";
      OnCalendar = "Mon 02:00";
      Persistent = true;
    };
    wantedBy = [ "timers.target" ];
  };
}
