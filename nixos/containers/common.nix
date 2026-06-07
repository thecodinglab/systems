{
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

  systemd.timers.podman-auto-update = {
    timerConfig = {
      Unit = "podman-auto-update.service";
      OnCalendar = "Mon 02:00";
      Persistent = true;
    };
    wantedBy = [ "timers.target" ];
  };
}
