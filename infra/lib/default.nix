lib':
let
  lib = builtins.foldl' (acc: mod: acc // import mod lib) lib' [
    ./cloudflare.nix
    ./home.nix
  ];
in
lib
