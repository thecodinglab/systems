{
  stdenv,
  lib,
  dpkg,
  autoPatchelfHook,
  makeWrapper,
  alsa-lib,
  at-spi2-atk,
  at-spi2-core,
  atk,
  cairo,
  cups,
  dbus,
  expat,
  glib,
  gtk3,
  libcap_ng,
  libdrm,
  libgbm,
  libglvnd,
  libnotify,
  libpulseaudio,
  libseccomp,
  libsecret,
  libuuid,
  libxcb,
  libxkbcommon,
  nspr,
  nss,
  pango,
  pipewire,
  systemd,
  xdg-utils,
  libx11,
  libxcomposite,
  libxdamage,
  libxext,
  libxfixes,
  libxrandr,
  deps,
}:
stdenv.mkDerivation {
  inherit (deps.claude-desktop) pname version src;

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
    makeWrapper
  ];

  buildInputs = [
    alsa-lib
    at-spi2-atk
    at-spi2-core
    atk
    cairo
    cups
    dbus
    expat
    glib
    gtk3 # also provides GSETTINGS_SCHEMAS_PATH
    libcap_ng
    libdrm
    libgbm
    libseccomp
    libxcb
    libxkbcommon
    nspr
    nss
    pango
    systemd
    libx11
    libxcomposite
    libxdamage
    libxext
    libxfixes
    libxrandr
  ];

  # opened through dlopen at runtime, so autoPatchelf cannot discover them
  runtimeDependencies = [
    libnotify
    libpulseaudio
    libsecret
    libuuid
    pipewire
  ];

  # the bundled ANGLE libEGL.so dlopens the native libEGL.so.1, and runtimeDependencies
  # only lands on executables, not on the shared objects next to them
  appendRunpaths = [ "${lib.getLib libglvnd}/lib" ];

  dontUnpack = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    # `dpkg -x` chokes on the setuid chrome-sandbox, so unpack the tarball directly
    dpkg --fsys-tarfile $src | tar --extract --no-same-permissions --no-same-owner

    rm -rf usr/share/lintian usr/share/doc

    mkdir -p $out
    mv usr/lib usr/share $out

    # replace the dangling /usr/bin symlink with a launcher
    mkdir -p $out/bin
    makeWrapper $out/lib/claude-desktop/claude-desktop $out/bin/claude-desktop \
      --prefix XDG_DATA_DIRS : "$GSETTINGS_SCHEMAS_PATH" \
      --suffix PATH : ${lib.makeBinPath [ xdg-utils ]} \
      --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations,WebRTCPipeWireCapturer --enable-wayland-ime=true}}"

    substituteInPlace $out/share/applications/com.anthropic.Claude.desktop \
      --replace-fail "Exec=claude-desktop" "Exec=$out/bin/claude-desktop"

    runHook postInstall
  '';

  meta = {
    description = "Desktop application for Claude.ai";
    homepage = "https://claude.ai";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "claude-desktop";
  };
}
