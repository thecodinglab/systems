{ pkgs }:
let
  mkFont =
    {
      pname,
      version,
      src,
      patchFont ? false,
    }:
    pkgs.stdenv.mkDerivation {
      inherit pname version src;

      unpackPhase = ''
        runHook preUnpack

        ${pkgs.lib.getExe' pkgs.p7zip "7z"} x $src
        find -name '*.pkg' -exec ${pkgs.lib.getExe' pkgs.p7zip "7z"} x {} \;
        ${pkgs.lib.getExe' pkgs.p7zip "7z"} x 'Payload~'

        runHook postUnpack
      '';

      buildPhase = ''
        runHook preBuild

        ${pkgs.lib.optionalString patchFont ''
          find Library/Fonts -name '*.otf' -exec ${pkgs.lib.getExe pkgs.nerd-font-patcher} -c {} \;
          find Library/Fonts -name '*.ttf' -exec ${pkgs.lib.getExe pkgs.nerd-font-patcher} -c {} \;
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
      sha256 = "sha256:1krvzxz7kal6y0l5cx9svmgikqdj5v0fl5vnfjig0z4nwp903ir1";
    };
  };

  apple-font-sf-compact = mkFont {
    pname = "apple-font-sf-compact";
    version = "1.0.0";
    src = builtins.fetchurl {
      url = "https://devimages-cdn.apple.com/design/resources/download/SF-Compact.dmg";
      sha256 = "sha256:0ncybkrzqazw13azy2s30ss7ml5pxaia6hbmqq9wn7xhlhrxlniy";
    };
  };

  apple-font-sf-mono = mkFont {
    pname = "apple-font-sf-mono";
    version = "1.0.0";
    src = builtins.fetchurl {
      url = "https://devimages-cdn.apple.com/design/resources/download/SF-Mono.dmg";
      sha256 = "sha256:0ibrk9fvbq52f5qnv1a8xlsazd3x3jnwwhpn2gwhdkdawdw0njkd";
    };
    patchFont = true;
  };

  apple-font-new-york = mkFont {
    pname = "apple-font-new-york";
    version = "1.0.0";
    src = builtins.fetchurl {
      url = "https://devimages-cdn.apple.com/design/resources/download/NY.dmg";
      sha256 = "sha256:1x7qi3dqwq1p4l3md31cd93mcds3ba7rgsmpz0kg7h3caasfsbhw";
    };
  };
}
