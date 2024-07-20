{
  config,
  pkgs,
  lib,
  ...
}:
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
  programs.tofi = lib.mkIf config.custom.catppuccin.enable {
    settings = fromINI "${sources.tofi}/themes/catppuccin-${config.custom.catppuccin.flavor}";
  };
}
