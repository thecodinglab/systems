{
  stdenv,
  fetchurl,
  autoPatchelfHook,
  copyDesktopItems,
  gtk3,
  alsa-lib,
  dbus-glib,
  xorg,
}:
stdenv.mkDerivation rec {
  pname = "tableplus";
  version = "0.1.264";

  src = fetchurl {
    url = "https://deb.tableplus.com/debian/24/pool/main/t/tableplus/tableplus_${version}_amd64.deb";
    # nix store prefetch-file "https://deb.tableplus.com/debian/24/pool/main/t/tableplus/tableplus_0.1.264_amd64.deb" --json | jq -r .hash
    hash = "sha256-FozNAz+NXMN39k3cA+NNE8O0RJdSI54A1BbrqDgXTLY=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    copyDesktopItems
  ];

  buildInputs = [
    gtk3
    alsa-lib
    dbus-glib
    xorg.libXtst
  ];

  unpackPhase = ''
    ar x $src
    tar xf data.tar.xz
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/share

    cp -a $src/opt/* $out/share
    ln -s $out/share/tableplus/tableplus $out/bin/tableplus

    runHook postInstall
  '';

  # preFixup = ''
  #   gappsWrapperArgs+=(
  #     --prefix LD_LIBRARY_PATH : "${
  #       lib.makeLibraryPath [
  #         pciutils
  #         pipewire
  #         libva
  #         libglvnd
  #         ffmpeg
  #       ]
  #     }"
  #   )
  #   gappsWrapperArgs+=(--set MOZ_LEGACY_PROFILES 1)
  #   wrapGApp $out/lib/zen/zen
  # '';

  # meta = with lib; {
  #   license = licenses.mpl20;
  #   maintainers = with maintainers; [ mordrag ];
  #   description = "Experience tranquillity while browsing the web without people tracking you! ";
  #   platforms = platforms.linux;
  #   mainProgram = "zen";
  # };
}
