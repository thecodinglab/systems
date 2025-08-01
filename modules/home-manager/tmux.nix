{
  config,
  pkgs,
  lib,
  ...
}:
{
  options.custom.tmux = {
    enable = lib.mkEnableOption "enable tmux";
  };

  config = lib.mkIf config.custom.tmux.enable {
    custom.fzf.enable = true;

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
        {
          plugin = pkgs.tmuxPlugins.sensible;
          extraConfig = ''
            set -g default-command '${lib.getExe pkgs.zsh}'
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
          bind-key o display-popup -E "${lib.getExe pkgs.tmux-sessionizer}"
        ''
        # tmux and nvim navigation
        ''
          # Smart pane switching with awareness of Vim splits.
          # See: https://github.com/christoomey/vim-tmux-navigator
          is_vim="ps -o state= -o comm= -t '#{pane_tty}' | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?(view|l?n?vim?x?|fzf)(diff)?$'"
          bind-key -n 'C-h' if-shell "$is_vim" 'send-keys C-h' 'select-pane -L'
          bind-key -n 'C-j' if-shell "$is_vim" 'send-keys C-j' 'select-pane -D'
          bind-key -n 'C-k' if-shell "$is_vim" 'send-keys C-k' 'select-pane -U'
          bind-key -n 'C-l' if-shell "$is_vim" 'send-keys C-l' 'select-pane -R'

          bind-key -T copy-mode-vi 'C-h' select-pane -L
          bind-key -T copy-mode-vi 'C-j' select-pane -D
          bind-key -T copy-mode-vi 'C-k' select-pane -U
          bind-key -T copy-mode-vi 'C-l' select-pane -R
          bind-key -T copy-mode-vi 'C-\' select-pane -l
        ''
      ];
    };

    programs.fzf.tmux.enableShellIntegration = true;

    home.packages = [ pkgs.tmux-sessionizer ];
  };
}
