{
  stdenvNoCC,
  lib,
  autoPatchelfHook,
  makeWrapper,
  zstd,
  alsa-lib,
  procps,
  ripgrep,
  bubblewrap,
  socat,
  versionCheckHook,
  writableTmpDirAsHomeHook,
  deps,
}:
let
  stdenv = stdenvNoCC;
  system = stdenv.hostPlatform.system;
  dep = deps."claude-code-${system}" or (throw "claude-code: no prefetched binary for ${system}");
in
stdenv.mkDerivation {
  pname = "claude-code";
  inherit (dep) version src;

  nativeBuildInputs = [
    makeWrapper
    zstd
  ]
  ++ lib.optionals stdenv.hostPlatform.isElf [ autoPatchelfHook ];

  strictDeps = true;

  dontUnpack = true;
  dontBuild = true;
  # stripping the bun-compiled binary drops the embedded application, leaving only the runtime
  dontStrip = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    unzstd -q $src -o $out/bin/claude
    chmod 755 $out/bin/claude

    wrapProgram $out/bin/claude \
      --set DISABLE_AUTOUPDATER 1 \
      --set-default FORCE_AUTOUPDATE_PLUGINS 1 \
      --set DISABLE_INSTALLATION_CHECKS 1 \
      --set USE_BUILTIN_RIPGREP 0 \
      ${lib.optionalString stdenv.hostPlatform.isLinux ''
        --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ alsa-lib ]} \
      ''}--prefix PATH : ${
        lib.makeBinPath (
          [
            procps # process tree handling needs pgrep (darwin) / ps (linux)
            ripgrep
          ]
          # required by the sandbox (linux only)
          ++ lib.optionals stdenv.hostPlatform.isLinux [
            bubblewrap
            socat
          ]
        )
      }

    runHook postInstall
  '';

  doInstallCheck = true;
  nativeInstallCheckInputs = [
    writableTmpDirAsHomeHook
    versionCheckHook
  ];
  versionCheckKeepEnvironment = [ "HOME" ];
  versionCheckProgramArg = "--version";

  meta = {
    description = "Agentic coding tool that lives in your terminal";
    homepage = "https://claude.com/product/claude-code";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    license = lib.licenses.unfree;
    platforms = [
      "x86_64-linux"
      "aarch64-darwin"
    ];
    mainProgram = "claude";
  };
}
