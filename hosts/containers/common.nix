{
  config,
  lib,
  modulesPath,
  pkgs,
  keys,
  ...
}:
{
  imports = [ (modulesPath + "/virtualisation/lxc-container.nix") ];

  nixpkgs.hostPlatform = "x86_64-linux";

  networking.nftables.enable = false;

  environment.systemPackages = [ pkgs.neovim-minimal ];

  users.users.root = {
    shell = pkgs.zsh;

    openssh.authorizedKeys.keys = [ keys.personal ];
  };

  home-manager.users.root = {
    home.stateVersion = "23.11";

    # useUserPackages would otherwise turn it on along with the system's
    # fontconfig; this user has no fonts of its own
    fonts.fontconfig.enable = false;

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
