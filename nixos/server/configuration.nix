{ outputs, pkgs, ... }:
{
  system.stateVersion = "23.11";

  imports = [
    # System
    ./hardware.nix

    ./ups.nix
    ./incus.nix

    # User
    ./users/nix
  ];

  nixpkgs.overlays = [
    outputs.overlays.additions
    outputs.overlays.modifications
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
    useDHCP = false;
    hostName = "server";

    interfaces.eno1 = {
      useDHCP = true;
    };

    bridges = {
      br0 = {
        interfaces = [ "eno2" ];
      };
    };

    nftables.enable = true;

    firewall = {
      allowedTCPPorts = [
        22 # ssh
        8443 # incus api
        5201 # iperf
      ];
      allowedUDPPorts = [ ];

      trustedInterfaces = [ "eno2" ];
    };
  };

  #######################
  # Applications        #
  #######################

  environment.systemPackages = [
    pkgs.bridge-utils
    pkgs.tcpdump
    pkgs.iperf
  ];
}
