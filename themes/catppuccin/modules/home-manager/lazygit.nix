{ config, pkgs, lib, ... }:
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
  programs.lazygit.settings = lib.mkIf config.catppuccin.enable
    (fromYaml "${sources.lazygit}/themes/${config.catppuccin.flavor}/${config.catppuccin.accent}.yml");
}
