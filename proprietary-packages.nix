{ lib, ... }: {
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    # Nvidia Drivers
    "nvidia-x11"
    "nvidia-settings"

    # Applications
    "1password"
    "1password-cli"
    "spotify"
    "smartgithg"
    "plexmediaserver"
    "steam"
    "steam-original"
    "obsidian"
    "staruml"
    "raycast"
  ];
}
