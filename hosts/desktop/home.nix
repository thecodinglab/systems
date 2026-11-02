{ ... }:
{
  imports = [
    ../../home/florian
    ../../home/florian/linux.nix
    ../../home/florian/dev.nix
    ../../home/florian/writing.nix
  ];

  # AirPods Max, toggled with Super+B
  custom.hyprland.headphones = "90:62:3F:9B:23:F7";

  # off by default: enable once the user_florian age key is on this machine
  # and the secret is migrated, see home/florian/writing.nix
  # custom.writing.languageTool.enable = true;
}
