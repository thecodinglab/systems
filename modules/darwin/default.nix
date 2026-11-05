{
  cliproxyapi = import ./cliproxyapi.nix;
  cloudflared = import ./cloudflared.nix;
  common = import ./common.nix;
  proxy = import ./proxy.nix;
  smb-mounts = import ./smb-mounts.nix;
}
