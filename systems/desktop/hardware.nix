{ config, lib, pkgs, modulesPath, ... }:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usb_storage" "usbhid" "sd_mod" ];
  boot.initrd.kernelModules = [ ];

  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/365e5d1a-cdc3-4270-9ff5-ec551cdc02d5";
    fsType = "btrfs";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/6771-AEAF";
    fsType = "vfat";
  };

  fileSystems."/media/data" = {
    device = "/dev/disk/by-uuid/d7f2ec8c-6cce-43be-ae74-aff6dc861387";
    fsType = "btrfs";
  };

  swapDevices = [ ];

  hardware = {
    bluetooth = {
      enable = true;
      settings = {
        General.Experimental = true;
      };
    };

    i2c.enable = true;
  };

  networking = {
    useDHCP = false;
    interfaces = {
      enp14s0.useDHCP = true;
      wlp12s0.useDHCP = true;
      wlp15s0.useDHCP = false;
    };
  };

  nixpkgs.hostPlatform = "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = config.hardware.enableRedistributableFirmware;
}
