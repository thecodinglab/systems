{ pkgs, lib, ... }:
let
  tmux-nvim = pkgs.tmuxPlugins.mkTmuxPlugin (
    let pkg = pkgs.vimPlugins.tmux-nvim; in {
      pluginName = "tmux.nvim";
      version = pkg.version;
      src = pkg.src;
    }
  );
in
{
  imports = [ ../fzf ];

  programs.tmux = {
    enable = true;
    clock24 = true;
    baseIndex = 1;
    customPaneNavigationAndResize = true;
    keyMode = "vi";
    secureSocket = true;
    shortcut = "Space";

    plugins = [
      pkgs.tmuxPlugins.yank
      pkgs.tmuxPlugins.sensible
      {
        plugin = pkgs.tmuxPlugins.resurrect;
        extraConfig = ''
          set -g @resurrect-strategy-nvim 'session'
        '';
      }
      {
        plugin = pkgs.tmuxPlugins.continuum;
        extraConfig = ''
          set -g @continuum-restore 'on'
          set -g @continuum-save-interval '60' # minutes
        '';
      }
      {
        plugin = tmux-nvim;
        extraConfig = ''
          set -g @tmux-nvim-navigation true
          set -g @tmux-nvim-navigation-cycle false
          set -g @tmux-nvim-resize true
        '';
      }
    ];

    extraConfig = lib.concatStringsSep "\n" [
      # fix colors
      ''
        set-option -sa terminal-overrides ",xterm*:Tc"
      ''
      # status bar length
      ''
        set -g status-left-length 80
        set -g status-right-length 80
      ''
      # general options
      ''
        set-option -g renumber-windows on
        set -g main-pane-height 80%
        set -g main-pane-width 60%
      ''
      # improve vi selection mode
      ''
        bind-key -T copy-mode-vi 'v' send -X begin-selection
        bind-key -T copy-mode-vi 'C-v' send -X rectangle-toggle
        bind-key -T copy-mode-vi 'y' send -X copy-selection-and-cancel
      ''
      # open new panes in the current directory
      ''
        bind '"' split-window -c "#{pane_current_path}"
        bind '%' split-window -h -c "#{pane_current_path}"
      ''
      # select project / pane
      ''
        bind-key o display-popup -E "${lib.getExe pkgs.tmux-sessionizer} switch"
      ''
    ];
  };

  programs.fzf.tmux.enableShellIntegration = true;

  home.packages = [
    pkgs.tmux-sessionizer
  ];
}
