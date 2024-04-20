{ lib, stdenv, obsidian }: stdenv.mkDerivation {
  pname = obsidian.pname;
  version = obsidian.version;

  src = obsidian;

  patches = lib.optional stdenv.isLinux ./wayland.patch;

  installPhase = ''
    mkdir -p $out
    cp -r . $out
  '';
}
