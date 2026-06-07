{
  audio = import ./audio.nix;
  backup = import ./backup.nix;
  common = import ./common.nix;
  desktop = import ./desktop;
  dynamic-brightness = import ./dynamic-brightness.nix;
  gaming = import ./gaming.nix;
  nvidia = import ./nvidia.nix;
  vpn = import ./vpn;
}
