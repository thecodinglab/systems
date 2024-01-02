{ ... }: {
  # SSH
  services.openssh.enable = true;
  programs.ssh.startAgent = true;

  # GPG
  programs.gnupg.agent = {
    enable = true;
    pinentryFlavor = "qt";
  };

  # Firewall
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      2342
    ];
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
