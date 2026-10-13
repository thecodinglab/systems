# web management panel of CLIProxyAPI, built from source instead of letting
# the server download the release asset from github at runtime
{
  lib,
  stdenvNoCC,
  bun,
  nodejs,
  fetchFromGitHub,
  writableTmpDirAsHomeHook,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "cliproxyapi-management-center";
  version = "1.26.2";

  src = fetchFromGitHub {
    owner = "router-for-me";
    repo = "Cli-Proxy-API-Management-Center";
    tag = "v${finalAttrs.version}";
    hash = "sha256-S4j5baxcFpYlo5zXpeMDVLFYC35ZnuoOVgwzTty7OrQ=";
  };

  # the dependencies of every platform, so the hash is the same everywhere
  passthru.node_modules = stdenvNoCC.mkDerivation {
    pname = "${finalAttrs.pname}-node_modules";
    inherit (finalAttrs) version src;

    impureEnvVars = lib.fetchers.proxyImpureEnvVars;

    nativeBuildInputs = [
      bun
      writableTmpDirAsHomeHook
    ];

    dontConfigure = true;

    buildPhase = ''
      runHook preBuild
      bun install --cpu="*" --os="*" --frozen-lockfile --ignore-scripts --no-progress
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      cp -R node_modules $out
      runHook postInstall
    '';

    # would add references to the store
    dontFixup = true;

    outputHash = "sha256-SLZnFCP2WSdpfcKsQ3ENeQeS3ZArD14YShBmVD0aY24=";
    outputHashAlgo = "sha256";
    outputHashMode = "recursive";
  };

  nativeBuildInputs = [
    bun
    nodejs
  ];

  strictDeps = true;

  configurePhase = ''
    runHook preConfigure
    cp -R ${finalAttrs.passthru.node_modules} node_modules
    chmod -R u+w node_modules
    patchShebangs node_modules
    runHook postConfigure
  '';

  # what the release workflow does, VERSION ends up in the ui
  buildPhase = ''
    runHook preBuild
    VERSION=v${finalAttrs.version} bun run build
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -Dm644 dist/index.html $out/share/cliproxyapi/management.html
    runHook postInstall
  '';

  meta = {
    description = "Web management panel of CLIProxyAPI";
    homepage = "https://github.com/router-for-me/Cli-Proxy-API-Management-Center";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
  };
})
