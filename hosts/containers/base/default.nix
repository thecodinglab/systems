{ pkgs, modulesPath, ... }: {
  imports = [
    (modulesPath + "/virtualisation/lxc-container.nix")
    (import ../../../modules/common/ssh/authorized-keys.nix "root")
  ];

  time.timeZone = "Europe/Zurich";

  i18n = {
    supportedLocales = [ "en_US.UTF-8/UTF-8" ];
    defaultLocale = "en_US.UTF-8";
  };

  nix = {
    settings = {
      auto-optimise-store = true;
      experimental-features = [ "nix-command" "flakes" ];
    };

    gc = {
      automatic = true;
      dates = "daily";
      options = "--delete-older-than 7d";
    };
  };

  boot.isContainer = true;

  networking = {
    nftables.enable = true;
    firewall.enable = false;
  };

  environment.systemPackages = [
    pkgs.neovim
    pkgs.rsync
  ];

  services.openssh.enable = true;

  system.stateVersion = "23.11";
}
