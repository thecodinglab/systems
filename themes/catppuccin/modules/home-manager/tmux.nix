{ config, pkgs, lib, ... }: {
  programs.tmux.plugins = [
    (lib.mkIf config.catppuccin.enable {
      plugin = pkgs.tmuxPlugins.catppuccin;
      extraConfig = ''
        set -g @catppuccin_flavour '${config.catppuccin.flavor}'
      '';
    })
  ];
}
