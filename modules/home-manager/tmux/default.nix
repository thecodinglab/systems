{ pkgs, ... }:
let
  my-select-pane = pkgs.writeScriptBin "tmux-select-pane" (builtins.readFile ./scripts/select-pane.sh);
in
{
  programs.tmux = {
    enable = true;
    clock24 = true;
    baseIndex = 1;
    customPaneNavigationAndResize = true;
    keyMode = "vi";
    # newSession = true;
    secureSocket = true;
    shortcut = "Space";

    terminal = "screen-256color";

    plugins = with pkgs; [
      tmuxPlugins.sensible
      {
        plugin = tmuxPlugins.resurrect;
        extraConfig = ''
          set -g @resurrect-strategy-nvim 'session'
        '';
      }
      {
        plugin = tmuxPlugins.continuum;
        extraConfig = ''
          set -g @continuum-boot 'on'
          set -g @continuum-restore 'on'
        '';
      }
      tmuxPlugins.yank
      # tmuxPlugins.nvim
    ];

    extraConfig = ''
      set-option -g renumber-windows on

      # navigate windows
      bind C-h previous-window
      bind C-l next-window

      # improve vi selection mode
      bind-key -T copy-mode-vi 'v' send -X begin-selection
      bind-key -T copy-mode-vi 'C-v' send -X rectangle-toggle
      bind-key -T copy-mode-vi 'y' send -X copy-selection-and-cancel

      # open new panes in the current directory
      bind '"' split-window -c "#{pane_current_path}"
      bind '%' split-window -h -c "#{pane_current_path}"

      # select pane
      bind-key f run-shell -b "${my-select-pane}/bin/tmux-select-pane"
    '';
  };

  home.packages = [
    my-select-pane
  ];
}
