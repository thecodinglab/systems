#!/usr/bin/env sh

if [ $# -ne 1 ]; then
  echo "Usage: $0 ENVIRONMENT"
  exit 1
fi

nix develop "github:thecodinglab/nix-common#$1" --command zsh
