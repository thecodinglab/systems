{ lib, ... }: {
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    # Hardware
    "nvidia-x11"
    "nvidia-settings"

    # Applications
    "1password"
    "spotify"
    "smartgithg"
  ];
}
