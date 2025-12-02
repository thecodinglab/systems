{
  lib,
  appimageTools,
  fetchurl,
}:
appimageTools.wrapType2 rec {
  pname = "helium";
  version = "0.6.9.1";

  src = fetchurl {
    url = "https://github.com/imputnet/helium-linux/releases/download/${version}/helium-${version}-x86_64.AppImage";
    hash = "sha256-L59Sm5qgORlV3L2yM6C0R8lDRyk05jOZcD5JPhQtbJE=";
  };

  appimageContent = appimageTools.extract {
    inherit pname version src;
  };

  extraInstallCommands = ''
    mkdir -p $out/share/applications
    install ${appimageContent}/helium.desktop $out/share/applications/helium.desktop
    substituteInPlace $out/share/applications/helium.desktop --replace-fail 'Exec=AppRun' 'Exec=helium'

    mkdir -p $out/share/icons/hicolor/256x256/apps
    install ${appimageContent}/helium.png $out/share/icons/hicolor/256x256/apps/helium.png
  '';
}
