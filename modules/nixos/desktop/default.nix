{
  imports = [
    (import ./common.nix)
    (import ./x11.nix)
    (import ./wayland.nix)
  ];
}
