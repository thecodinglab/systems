{ config, pkgs, ... }:
let
  cfg = import ./config.nix {
    config = config.custom.nixvim;
    inherit pkgs;
  };
in
{
  options.custom.nixvim = cfg.options;
  config.programs.nixvim = cfg.config;
}
