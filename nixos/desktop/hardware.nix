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

  fileSystems."/media/data" = {
    device = "/dev/disk/by-uuid/d7f2ec8c-6cce-43be-ae74-aff6dc861387";
    fsType = "btrfs";
  };

  fileSystems."/media/server" = {
    device = "172.16.0.54:/";
    fsType = "nfs4";

    options = [
      "x-systemd.automount"
      "x-systemd.idle-timeout=600"
      "noauto"
    ];
  };

  swapDevices = [ ];

  nixpkgs.hostPlatform = "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = config.hardware.enableRedistributableFirmware;
}
