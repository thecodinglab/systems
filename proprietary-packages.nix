{ lib, ... }: {
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    # Nvidia Drivers
    "nvidia-x11"
    "nvidia-settings"

    # Nvidia Cuda
    "cuda_cccl"
    "cuda_cudart"
    "cuda_nvcc"
    "libcublas"

    # Applications
    "1password"
    "spotify"
    "smartgithg"
    "plexmediaserver"
    "steam"
    "steam-original"
    "obsidian"
  ];
}
