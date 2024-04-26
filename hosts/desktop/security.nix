{ pkgs, ... }: {
  # GPG
  programs.gnupg.agent = {
    enable = true;
    pinentryPackage = pkgs.pinentry-qt;
  };

  # Firewall
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ ];
    allowedUDPPorts = [ ];
  };

  # Gnome Keyring
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.lightdm.enableGnomeKeyring = true;
  programs.seahorse.enable = true;

  # ulimit
  security.pam.loginLimits = [
    { domain = "*"; type = "soft"; item = "nofile"; value = "unlimited"; }
  ];
}
