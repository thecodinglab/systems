{
  appimageTools,
  deps,
}:
appimageTools.wrapType2 rec {
  inherit (deps.helium) pname version src;

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
