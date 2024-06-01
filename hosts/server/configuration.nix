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
      enable = true;
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

  programs.zsh.enable = true;
  environment = {
    systemPackages = [ pkgs.iperf ];
    shells = [ pkgs.zsh ];
  };
}
