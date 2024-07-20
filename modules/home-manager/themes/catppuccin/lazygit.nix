{
  config,
  pkgs,
  lib,
  ...
}:
let
  sources = import ./npins;
  fromYaml =
    file:
    let
      json = pkgs.runCommand "converted.json" { } ''
        ${lib.getExe pkgs.yj} < ${file} > $out
      '';
    in
    builtins.fromJSON (builtins.readFile json);
in
{
  programs.lazygit.settings = lib.mkIf config.custom.catppuccin.enable (
    fromYaml "${sources.lazygit}/themes/${config.custom.catppuccin.flavor}/${config.custom.catppuccin.accent}.yml"
  );
}
