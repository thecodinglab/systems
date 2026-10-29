{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.custom.tmux;
  tmux = lib.getExe config.programs.tmux.package;
  agentLabel = "org.nix-community.home.tmux";
  inherit (pkgs.stdenv.hostPlatform) isDarwin;
in
{
  options.custom.tmux = {
    enable = lib.mkEnableOption "enable tmux";
  };

  config = lib.mkIf cfg.enable {
    custom.fzf.enable = true;

    programs.tmux = {
      enable = true;
      clock24 = true;
      baseIndex = 1;
      customPaneNavigationAndResize = true;
      keyMode = "vi";
      shortcut = "Space";

      plugins = [
        pkgs.tmuxPlugins.yank
        {
          plugin = pkgs.tmuxPlugins.sensible;
          extraConfig = ''
            set -g default-command '${lib.getExe pkgs.zsh}'
            set-environment -g TINTED_TMUX_OPTION_ACTIVE 1
            set-environment -g TINTED_TMUX_OPTION_STATUSBAR 1
            set-environment -g TERMINAL_BACKGROUND_TRANSPARENT 1
          '';
        }
      ];

      extraConfig = lib.mkAfter (
        lib.concatStringsSep "\n" [
          # fix colors
          ''
            set-option -sa terminal-overrides ",xterm*:Tc"
          ''
          # let terminal transparency/blur show through tmux panes
          ''
            set -g window-style "fg=default,bg=default"
            set -g window-active-style "fg=default,bg=default"
            set -g pane-border-style "bg=default"
              set -g pane-active-border-style "bg=default"
              set -g message-style "fg=default,bg=default"
              set -g popup-style "fg=default,bg=default"
              set -g mode-style "fg=default,bg=default,reverse"
          ''
          # status bar length
          ''
            # Hide stale theme output while the login shell is starting.
            # The zsh theme hook turns this back on after applying colors.
            set -g status off
            set -g status-left-length 80
            set -g status-right-length 80
          ''
          # general options
          ''
            set-option -g renumber-windows on
            set -g main-pane-height 80%
            set -g main-pane-width 60%

            # let programs inside tmux reach the system clipboard (OSC 52) and
            # send raw escapes (images, OSC 133) through to the terminal
            set -g set-clipboard on
            set -g allow-passthrough on
            set -as terminal-features ",*:clipboard"

            # forward modified keys (ctrl/shift/alt combos) to TUIs
            set -g extended-keys on
            set -g extended-keys-format csi-u

            # keep the terminal title in sync with the current window
            set -g set-titles on
            set -g set-titles-string '#h:#W'

            # jump to another session instead of detaching when one is killed
            set -g detach-on-destroy off
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
            bind-key o display-popup -w 90% -h 80% -E "devtools pick"
            bind-key s display-popup -w 90% -h 80% -E "devtools sessions"
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
        ]
      );
    };

    programs.fzf.tmux.enableShellIntegration = true;

    # an ssh login gets its own security session, which can't see the keychain
    # unlocked by the gui login (no codesign etc.); a server started by launchd
    # lives in the gui session and so do all of its panes
    launchd.agents.tmux = lib.mkIf isDarwin {
      enable = true;
      config = {
        # -D keeps the server in the foreground for launchd and turns
        # exit-empty off, so it stays up without sessions
        ProgramArguments = [
          tmux
          "-D"
        ];
        RunAtLoad = true;
        KeepAlive = true;
        ProcessType = "Interactive";
        # launchd hands agents a bare environment and panes inherit it
        EnvironmentVariables = {
          SHELL = lib.getExe pkgs.zsh;
          LANG = "en_US.UTF-8";
        };
      };
    };

    # never let an ssh login start the server, it would be stuck in the ssh
    # security session; -N connects to a running server only
    programs.zsh.initContent = lib.mkIf (isDarwin && config.custom.zsh.enable) ''
      tmux() {
        if [[ -n $SSH_CONNECTION && -z $TMUX ]] && ! command tmux -N start-server 2>/dev/null; then
          print -u2 "tmux: no server running, refusing to start one from ssh (the keychain would be locked)"
          print -u2 "tmux: start it in the gui session: launchctl kickstart gui/$UID/${agentLabel}"
          return 1
        fi
        command tmux "$@"
      }
    '';

    home.packages = [ pkgs.devtools ];
  };
}
