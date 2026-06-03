{
  audio = import ./audio.nix;
  backup = import ./backup.nix;
  common = import ./common.nix;
  container = import ./container.nix;
  desktop = import ./desktop;
  dynamic-brightness = import ./dynamic-brightness.nix;
  nvidia = import ./nvidia.nix;
  vpn = import ./vpn;
  wooting = import ./wooting.nix;
  zsa = import ./zsa.nix;
}
