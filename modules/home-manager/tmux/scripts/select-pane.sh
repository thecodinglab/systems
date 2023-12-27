#!/usr/bin/env sh

set -e

if [ -z "$TMUX" ]; then
  echo "This script must be run from within tmux."
  exit 1
fi

FORMAT='#{session_id}:#{window_id}:#{pane_id} #{session_name} #{window_name} #{pane_current_path} #{pane_current_command}'
PANES=$(tmux list-panes -a -F "$FORMAT")

SELECTION=$(echo "${PANES}" | fzf-tmux -p | awk '{print $1}')
if [ -z "$SELECTION" ]; then
  exit 0
fi

ARGS=(${SELECTION//:/ })
tmux select-pane -t "${ARGS[2]}"
tmux select-window -t "${ARGS[1]}"
tmux switch-client -t "${ARGS[0]}"
