{ config, pkgs, lib, ... }:
let
  src = pkgs.fetchFromGitHub {
    owner = "catppuccin";
    repo = "kitty";
    rev = "d7d61716a83cd135344cbb353af9d197c5d7cec1";
    hash = "sha256-mRFa+40fuJCUrR1o4zMi7AlgjRtFmii4fNsQyD8hIjM=";
  };
in
{
  programs.kitty.settings = lib.mkIf config.catppuccin.enable {
    include = "${src}/themes/${config.catppuccin.flavor}.conf";
  };
}
