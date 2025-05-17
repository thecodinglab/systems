{
  audio = import ./audio.nix;
  backup = import ./backup.nix;
  common = import ./common.nix;
  container = import ./container.nix;
  desktop = import ./desktop;
  dynamic-brightness = import ./dynamic-brightness.nix;
  nvidia = import ./nvidia.nix;
  vpn = import ./vpn;
  zsa = import ./zsa.nix;

  unfree = import ../unfree.nix;
}
