{ lib, stdenv, spotify }: stdenv.mkDerivation {
  pname = spotify.pname;
  version = spotify.version;

  src = spotify;

  patches = lib.optional stdenv.isLinux ./wayland.patch;

  installPhase = ''
    mkdir -p $out
    cp -r . $out
  '';
}
