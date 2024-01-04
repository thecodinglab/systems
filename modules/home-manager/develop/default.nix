{ pkgs, ... }: {
  home.packages = [
    (pkgs.writeShellScriptBin "develop" (builtins.readFile ./scripts/develop.sh))
  ];
}
