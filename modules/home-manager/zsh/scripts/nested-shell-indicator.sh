if [ -z "$SHELL_DEPTH" ]; then
  export SHELL_DEPTH=0
else
  export SHELL_DEPTH=$(expr $SHELL_DEPTH + 1)
fi

function nested_shell_indicator() {
  if [ "$SHELL_DEPTH" -eq 1 ]; then
    echo " ";
  elif [ "$SHELL_DEPTH" -gt 1 ]; then
    echo " (${SHELL_DEPTH}x) ";
  fi
}

RPS1="%F{yellow}%b$(nested_shell_indicator)%f$RPS1"
