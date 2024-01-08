{ modulesPath, root, neovim-config, ... }: {
  imports = [
    (modulesPath + "/virtualisation/lxc-container.nix")
    (import (root + "/modules/common/ssh/authorized-keys.nix") "root")
  ];

  time.timeZone = "Europe/Zurich";

  i18n = {
    supportedLocales = [ "en_US.UTF-8/UTF-8" ];
    defaultLocale = "en_US.UTF-8";
  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  boot.isContainer = true;

  networking = {
    # use nftables firewall instead of iptables
    nftables.enable = true;

    firewall.enable = true;
  };

  system.environmentPackages = [
    neovim-config.packages.x86_64-linux.prebuilt
  ];
  
  services.openssh.enable = true;

  system.stateVersion = "23.11";
}
