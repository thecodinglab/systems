{
  config,
  pkgs,
  lib,
  ...
}:
{
  programs.tmux.plugins = [ (lib.mkIf config.nord.enable pkgs.tmuxPlugins.nord) ];
}
