{ ... }: {
  time.timeZone = "Europe/Zurich";

  i18n = {
    supportedLocales = [ "en_US.UTF-8/UTF-8" ];
    defaultLocale = "en_US.UTF-8";
  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  boot.isContainer = true;
  networking.firewall.enable = false;

  system.stateVersion = "23.11";
}
