{
  config,
  pkgs,
  lib,
  ...
}:
{
  programs.tmux.plugins = [
    (lib.mkIf config.custom.catppuccin.enable {
      plugin = pkgs.tmuxPlugins.catppuccin;
      extraConfig = ''
        set -g @catppuccin_flavour '${config.custom.catppuccin.flavor}'
      '';
    })
  ];
}
