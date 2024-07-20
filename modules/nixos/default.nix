{
  audio = import ./audio.nix;
  backup = import ./backup.nix;
  common = import ./common.nix;
  desktop = import ./desktop;
  dynamic-brightness = import ./dynamic-brightness.nix;
  nvidia = import ./nvidia.nix;

  unfree = import ../unfree.nix;
}
