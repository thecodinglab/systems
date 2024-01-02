function in_nix_shell() {
  if [ ! -z ''${IN_NIX_SHELL+x} ]; then
    return 0
  fi

  if [ "$SHLVL" -gt 1 ]; then
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
