# public keys shared across hosts and modules
{
  # personal ssh key (1Password), allowed to log into every machine
  personal = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKrk+aYPC9+XPBzYI6uuxRbczvimV1Brclkic873p0Uv";

  # the nix-daemons' keys for remote builds: the desktop builds darwin on the
  # mini, the macs build x86_64-linux on the desktop. Only allowed to run
  # nix-daemon on the other side. The private keys are nix_builder_ssh_key in
  # each host's secrets.yaml (the macbook's in hosts/macbookpro).
  nixBuilders = {
    desktop = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA6Rxb13U+BM4I3mAk0lizaJniMZRgz9HZ//OUFxS+PZ nix-builder@desktop";
    macmini = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBIKvQNZJgwaLsub59Q+0rqx42gJi6eSn+Qcu4b/tB81 nix-builder@macmini";
    macbook = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGf4ZkRjMLoRsc/CEyXjBtuBUjGVd45VFKLBS2yJhhNa nix-builder@macbook";
  };

  # key git commits are signed with
  signing = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILrUBNULG42gQY1Y0Na+DFocGXrr1dZYfIXIXrwpjcxG";
}
