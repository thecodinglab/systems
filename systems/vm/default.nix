{ lib, pkgs, home-manager, root, ... }:
{
  system.stateVersion = "23.11";

  imports = [
    # System
    (root + "/modules/nixos/base")

    # User
    ./users/florian
  ];

  #######################
  # Resources           #
  #######################

  virtualisation.vmVariant = {
    virtualisation = {
      cores = 4;
      memorySize = 16384; # 16 GiB
      diskSize = 8192; # 8 GiB
    };
  };

  #######################
  # General             #
  #######################

  time = {
    timeZone = "Europe/Zurich";
    hardwareClockInLocalTime = true;
  };

  i18n = {
    supportedLocales = [ "en_US.UTF-8/UTF-8" "de_CH.UTF-8/UTF-8" ];
    defaultLocale = "en_US.UTF-8";
  };

  console = {
    font = "Lat2-Terminus16";
    useXkbConfig = true;
  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  #######################
  # Boot                #
  #######################

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  #######################
  # Networking          #
  #######################

  networking.hostName = "florian-nixos-vm";
}

