function in_nix_shell() {
  if [ ! -z ''${IN_NIX_SHELL+x} ]; then
    return 0
  fi
  
  LVL="$SHLVL"
  if [ -n "$TMUX" ]; then
    # since tmux opens nested shells, the level of shells is incremented by one
    # to prevent showing the nix indicator on every tmux pane, the level is
    # decremented here.
    LVL=$((LVL - 1))
  fi

  if [ "$LVL" -gt 1 ]; then
    return 0
  fi

  return 1
}

function nix_shell_indicator() {
  if in_nix_shell; then
    echo " nix ";
  fi
}

RPS1="%F{yellow}%b$(nix_shell_indicator)%f$RPS1"
