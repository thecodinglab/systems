{ config, modulesPath, ... }:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "ahci"
    "usbhid"
    "sd_mod"
  ];
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

  swapDevices = [ ];

  nixpkgs.hostPlatform = "x86_64-linux";

  hardware = {
    cpu.amd.updateMicrocode = config.hardware.enableRedistributableFirmware;
    i2c.enable = true;
  };
}
