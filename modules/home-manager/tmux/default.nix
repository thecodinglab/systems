{ pkgs, lib, root, ... }:
let
  tmux-select-pane =
    pkgs.writeShellScriptBin
      "tmux-select-pane"
      (builtins.readFile ./scripts/select-pane.sh);

  tmux-nvim = pkgs.tmuxPlugins.mkTmuxPlugin {
    pluginName = "tmux.nvim";
    version = "unstable-2023-10-28";
    src = pkgs.fetchFromGitHub {
      owner = "aserowy";
      repo = "tmux.nvim";
      rev = "ea67d59721eb7e12144ce2963452e869bfd60526";
      hash = "sha256-/2flPlSrXDcNYS5HJjf8RbrgmysHmNVYYVv8z3TLFwg=";
    };
  };
in
{
  imports = [
    (root + "/modules/home-manager/fzf")
  ];

  programs.tmux = {
    enable = true;
    clock24 = true;
    baseIndex = 1;
    customPaneNavigationAndResize = true;
    keyMode = "vi";
    secureSocket = true;
    shortcut = "Space";

    plugins = with pkgs.tmuxPlugins; [
      nord
      yank
      sensible
      {
        plugin = resurrect;
        extraConfig = ''
          set -g @resurrect-strategy-nvim 'session'
        '';
      }
      {
        plugin = continuum;
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
          set -g @tmux-nvim-resize false
        '';
      }
    ];

    extraConfig = lib.concatStringsSep "\n" [
      # fix colors inside tmux
      ''
        set -g default-terminal "screen-256color"
        set -ag terminal-overrides ",xterm-256color:RGB"
      ''
      # status bar length
      ''
        set -g status-left-length 80
        set -g status-right-length 80
      ''
      # general options options
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
        bind-key o display-popup -E "${pkgs.tmux-sessionizer}/bin/tms switch"
        bind-key f run-shell -b "${tmux-select-pane}/bin/tmux-select-pane"
      ''
    ];
  };

  programs.fzf.tmux.enableShellIntegration = true;

  home.packages = [
    tmux-select-pane
    pkgs.tmux-sessionizer
  ];
}
