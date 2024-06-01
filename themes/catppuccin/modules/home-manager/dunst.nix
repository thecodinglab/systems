{ config, pkgs, lib, ... }:
let
  sources = import ./npins;
  fromINI =
    file:
    let
      # convert to json
      json = pkgs.runCommand "converted.json" { } ''
        ${lib.getExe pkgs.jc} --ini < ${file} > $out
      '';
    in
    builtins.fromJSON (builtins.readFile json);
in
{
  services.dunst.settings = lib.mkIf config.catppuccin.enable
    (fromINI "${sources.dunst}/themes/${config.catppuccin.flavor}.conf");
}
