{ pkgs, ... }:
{
  system.stateVersion = "23.11";

  imports = [
    # System
    ./hardware.nix

    ./ups.nix
    ./incus.nix

    ../../modules/nixos/base
    ../../modules/nixos/ssh

    # User
    ./users/nix
  ];

  #######################
  # General             #
  #######################

  time.timeZone = "Europe/Zurich";

  i18n = {
    supportedLocales = [ "en_US.UTF-8/UTF-8" ];
    defaultLocale = "en_US.UTF-8";
  };

  console.font = "Lat2-Terminus16";

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  security.sudo = {
    wheelNeedsPassword = false;
    execWheelOnly = true;
  };

  #######################
  # Boot                #
  #######################

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  #######################
  # Networking          #
  #######################

  networking = {
    useDHCP = true;
    hostName = "server";

    interfaces.eno1 = {
      useDHCP = true;
    };

    bridges = {
      br0 = {
        interfaces = [ "eno2" ];
      };
    };

    # use nftables firewall instead of iptables
    nftables.enable = true;

    firewall = {
      enable = true;
      allowedTCPPorts = [
        8443 # incus api
      ];
      allowedUDPPorts = [ ];

      trustedInterfaces = [ "eno2" ];
    };

    dhcpcd.denyInterfaces = [ "veth*" ];
  };

  #######################
  # Applications        #
  #######################

  programs.zsh.enable = true;
  environment.shells = [ pkgs.zsh ];
}
