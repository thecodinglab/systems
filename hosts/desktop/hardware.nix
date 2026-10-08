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
    options = [
      # no CoW metadata write for every file read
      "noatime"
      # near-free on this CPU, fewer bytes to the NVMe; only applies to newly
      # written data
      "compress=zstd:1"
      "ssd"
      # trim freed extents in the background instead of the weekly fstrim
      "discard=async"
      "space_cache=v2"
    ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/6771-AEAF";
    fsType = "vfat";
  };

  swapDevices = [ ];

  # root is mounted with discard=async, so the weekly run only re-trims the
  # whole disk for minutes after every boot catch-up
  services.fstrim.enable = false;

  # Return nearly empty chunks to the unallocated pool. Without it, btrfs
  # keeps allocated-but-unused metadata chunks around until the fs reports
  # ENOSPC with plenty of space free.
  systemd.services.btrfs-balance-light = {
    description = "Light btrfs balance of nearly empty chunks";
    serviceConfig = {
      Type = "oneshot";
      Nice = 19;
      ExecStart = "${lib.getExe' pkgs.btrfs-progs "btrfs"} balance start -dusage=10 -musage=20 /";
    };
  };
  systemd.timers.btrfs-balance-light = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "monthly";
      Persistent = true;
      RandomizedDelaySec = "1h";
    };
  };

  nixpkgs.hostPlatform = "x86_64-linux";

  hardware = {
    cpu.amd.updateMicrocode = config.hardware.enableRedistributableFirmware;
    i2c.enable = true;
  };
}
