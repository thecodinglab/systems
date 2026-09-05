{
  stdenvNoCC,
  lib,
  makeWrapper,
  ripgrep,
  bubblewrap,
  versionCheckHook,
  deps,
}:
let
  stdenv = stdenvNoCC;
  system = stdenv.hostPlatform.system;
  dep = deps."codex-${system}" or (throw "codex: no prefetched binary for ${system}");
in
stdenv.mkDerivation {
  pname = "codex";
  inherit (dep) version src;

  nativeBuildInputs = [ makeWrapper ];

  strictDeps = true;

  # the package tarball has no top-level directory, only bin/, codex-path/, codex-resources/
  sourceRoot = ".";
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    # codex looks for codex-code-mode-host next to its own executable, so it has
    # to live in the same directory as the wrapped binary. The bundled rg/bwrap
    # under codex-path/ and codex-resources/ are replaced by the nix packages.
    install -Dm755 -t $out/bin bin/codex bin/codex-code-mode-host

    wrapProgram $out/bin/codex \
      --prefix PATH : ${
        lib.makeBinPath ([ ripgrep ] ++ lib.optionals stdenv.hostPlatform.isLinux [ bubblewrap ])
      }

    runHook postInstall
  '';

  doInstallCheck = true;
  nativeInstallCheckInputs = [ versionCheckHook ];
  versionCheckProgramArg = "--version";

  meta = {
    description = "Lightweight coding agent that runs in your terminal";
    homepage = "https://github.com/openai/codex";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    license = lib.licenses.asl20;
    platforms = [
      "x86_64-linux"
      "aarch64-darwin"
    ];
    mainProgram = "codex";
  };
}
