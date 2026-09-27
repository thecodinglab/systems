# Helium is packaged from the plain linux tarball instead of the AppImage:
# AppImages run inside bubblewrap with `no_new_privs`, which prevents the
# setgid `1Password-BrowserSupport` native messaging host from working.
{
  lib,
  stdenvNoCC,
  makeWrapper,
  patchelf,
  bintools,
  addDriverRunpath,

  alsa-lib,
  at-spi2-atk,
  at-spi2-core,
  atk,
  bzip2,
  cairo,
  coreutils,
  cups,
  dbus,
  expat,
  fontconfig,
  freetype,
  gcc-unwrapped,
  gdk-pixbuf,
  glib,
  gsettings-desktop-schemas,
  adwaita-icon-theme,
  gtk3,
  gtk4,
  libdrm,
  libglvnd,
  libkrb5,
  libgbm,
  libpulseaudio,
  libva,
  libx11,
  libxcb,
  libxcomposite,
  libxcursor,
  libxdamage,
  libxext,
  libxfixes,
  libxi,
  libxkbcommon,
  libxrandr,
  libxrender,
  libxscrnsaver,
  libxshmfence,
  libxtst,
  nspr,
  nss,
  pango,
  pciutils,
  pipewire,
  systemd,
  vulkan-loader,
  wayland,
  xdg-utils,

  deps,
}:
let
  runtimeDeps = [
    alsa-lib
    at-spi2-atk
    at-spi2-core
    atk
    bzip2
    cairo
    coreutils
    cups
    dbus
    expat
    fontconfig
    freetype
    gcc-unwrapped.lib
    gdk-pixbuf
    glib
    gtk3
    gtk4
    libdrm
    libglvnd
    libkrb5
    libgbm
    libpulseaudio
    libva
    libx11
    libxcb
    libxcomposite
    libxcursor
    libxdamage
    libxext
    libxfixes
    libxi
    libxkbcommon
    libxrandr
    libxrender
    libxscrnsaver
    libxshmfence
    libxtst
    nspr
    nss
    pango
    pciutils
    pipewire
    systemd
    vulkan-loader
    wayland
  ];
in
stdenvNoCC.mkDerivation rec {
  inherit (deps.helium) pname version src;

  nativeBuildInputs = [
    makeWrapper
    patchelf
  ];

  buildInputs = [
    adwaita-icon-theme
    glib
    gtk3
    gtk4
    gsettings-desktop-schemas
  ];

  rpath = lib.makeLibraryPath runtimeDeps + ":" + lib.makeSearchPathOutput "lib" "lib64" runtimeDeps;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/share/applications $out/share/icons/hicolor/256x256/apps
    cp -a . $out/share/helium

    # qt shims would pull in qt, gtk is used instead
    rm $out/share/helium/libqt{5,6}_shim.so

    rm $out/share/helium/libvulkan.so.1
    ln -s ${lib.getLib vulkan-loader}/lib/libvulkan.so.1 $out/share/helium/libvulkan.so.1

    for elf in $out/share/helium/{helium,helium_crashpad_handler,chromedriver}; do
      patchelf --set-interpreter ${bintools.dynamicLinker} --set-rpath $rpath:$out/share/helium $elf
    done

    # the binary itself must stay named `helium` for the 1password browser allowlist
    makeWrapper $out/share/helium/helium $out/bin/helium \
      --prefix LD_LIBRARY_PATH : "$rpath:$out/share/helium" \
      --suffix PATH : "${lib.makeBinPath [ xdg-utils ]}" \
      --prefix XDG_DATA_DIRS : "$XDG_ICON_DIRS:$GSETTINGS_SCHEMAS_PATH:${addDriverRunpath.driverLink}/share" \
      --set CHROME_WRAPPER helium

    install -m644 helium.desktop $out/share/applications/helium.desktop
    substituteInPlace $out/share/applications/helium.desktop --replace-fail 'Exec=helium' 'Exec=helium --ozone-platform=wayland'

    install -m644 product_logo_256.png $out/share/icons/hicolor/256x256/apps/helium.png

    runHook postInstall
  '';

  meta = {
    description = "Private, fast, and honest web browser based on ungoogled-chromium";
    homepage = "https://helium.computer";
    license = lib.licenses.gpl3Only;
    platforms = [ "x86_64-linux" ];
    mainProgram = "helium";
  };
}
