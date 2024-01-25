let
  lib = {
    home = import ../../secrets/home-subnets.nix;
    cloudflare = (import ./cloudflare.nix) lib;
  };
in
lib
