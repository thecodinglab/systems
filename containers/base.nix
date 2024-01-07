{ modulesPath, ... }: {
  imports = [ (modulesPath + "/virtualisation/lxc-container.nix") ];

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

  system.stateVersion = "23.11";
}
