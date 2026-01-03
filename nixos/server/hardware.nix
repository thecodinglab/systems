{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules = [
    "ahci"
    "xhci_pci"
    "nvme"
    "usbhid"
    "sd_mod"
  ];
  boot.initrd.kernelModules = [ "dm-snapshot" ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/5d6e2cf7-0bee-4ee7-b39c-4730850d5b7d";
    fsType = "btrfs";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/709A-6F13";
    fsType = "vfat";
  };

  fileSystems."/media/unas/media" = {
    device = "192.168.32.185:/var/nfs/shared/Media";
    fsType = "nfs";
    options = [
      "x-systemd.automount"
      "x-systemd.idle-timeout=600"
      "noauto"
    ];
  };

  swapDevices = [ ];

  nixpkgs.hostPlatform = "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = config.hardware.enableRedistributableFirmware;
}
