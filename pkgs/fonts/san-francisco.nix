{
  lib,
  stdenv,
  p7zip,
  nerd-font-patcher,
}:
let
  mkFont =
    {
      pname,
      version,
      src,
      patchFont ? false,
    }:
    stdenv.mkDerivation {
      inherit pname version src;

      unpackPhase = ''
        runHook preUnpack

        ${lib.getExe' p7zip "7z"} x $src
        find -name '*.pkg' -exec ${lib.getExe' p7zip "7z"} x {} \;
        ${lib.getExe' p7zip "7z"} x 'Payload~'

        runHook postUnpack
      '';

      buildPhase = ''
        runHook preBuild

        ${lib.optionalString patchFont ''
          find Library/Fonts -name '*.otf' -exec ${lib.getExe nerd-font-patcher} -c {} \;
          find Library/Fonts -name '*.ttf' -exec ${lib.getExe nerd-font-patcher} -c {} \;
        ''}

        runHook postBuild
      '';

      installPhase = ''
        runHook preInstall

        find -name '*.otf' -exec mkdir -p $out/share/fonts/opentype/${pname} \; -exec mv {} $out/share/fonts/opentype/${pname} \;
        find -name '*.ttf' -exec mkdir -p $out/share/fonts/truetype/${pname} \; -exec mv {} $out/share/fonts/truetype/${pname} \;

        runHook postInstall
      '';
    };
in
{
  apple-font-sf-pro = mkFont {
    pname = "apple-font-sf-pro";
    version = "1.0.0";
    src = builtins.fetchurl {
      url = "https://devimages-cdn.apple.com/design/resources/download/SF-Pro.dmg";
      sha256 = "sha256:0ycxhncd6if94w5n8cpdwr8rhrqdhgi913plbr2q8fia2266bk07";
    };
  };

  apple-font-sf-compact = mkFont {
    pname = "apple-font-sf-compact";
    version = "1.0.0";
    src = builtins.fetchurl {
      url = "https://devimages-cdn.apple.com/design/resources/download/SF-Compact.dmg";
      sha256 = "sha256:0fkxm7nyl180qp8k2alynvy1w1a32zdm78dpq1zhv9q4gr1hp2ig";
    };
  };

  apple-font-sf-mono = mkFont {
    pname = "apple-font-sf-mono";
    version = "1.0.0";
    src = builtins.fetchurl {
      url = "https://devimages-cdn.apple.com/design/resources/download/SF-Mono.dmg";
      sha256 = "sha256:0psf2fkqpwzw3hifciph7ypvjklb4jkcgh0mair0xvlf6baz3aji";
    };
    patchFont = true;
  };

  apple-font-new-york = mkFont {
    pname = "apple-font-new-york";
    version = "1.0.0";
    src = builtins.fetchurl {
      url = "https://devimages-cdn.apple.com/design/resources/download/NY.dmg";
      sha256 = "sha256:1c5h9szggmwspba8gj06jlx30x83m9q6k9cdyg8dkivnij9am369";
    };
  };
}
