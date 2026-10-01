#!/usr/bin/env bash
# Update flake inputs and nvfetcher sources in one go and commit the result, so
# dependency bumps happen once here instead of independently on every machine.
#
# Usage: scripts/update.sh [input...]   (no arguments updates all flake inputs
#                                        and the nvfetcher sources)
#
# kakeibo is a private repository: updating it (also implicitly, without
# arguments) needs GitHub credentials for git, e.g. `gh auth setup-git`.
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

# Refuse to mix the update commit with unrelated pending changes.
if [[ -n "$(git status --porcelain -- flake.lock _sources)" ]]; then
  echo "error: flake.lock or _sources/ have uncommitted changes; commit or stash them first:" >&2
  git status --short -- flake.lock _sources >&2
  exit 1
fi

echo "==> Updating flake inputs${*:+: $*}"
nix flake update "$@"

# a targeted bump (e.g. only kakeibo) leaves the nvfetcher sources alone
if [[ $# -eq 0 ]]; then
  echo "==> Updating nvfetcher sources"
  nvfetcher_args=(--config nvfetcher.toml --build-dir _sources)
  keyfile=""
  if command -v gh >/dev/null 2>&1 && token="$(gh auth token 2>/dev/null)"; then
    # Authenticated GitHub requests avoid the anonymous API rate limit.
    keyfile="$(mktemp)"
    trap 'rm -f "$keyfile"' EXIT
    printf '[keys]\ngithub = "%s"\n' "$token" >"$keyfile"
    nvfetcher_args+=(--keyfile "$keyfile")
  fi
  nix run --inputs-from . nixpkgs#nvfetcher -- "${nvfetcher_args[@]}"
fi

if [[ -z "$(git status --porcelain -- flake.lock _sources)" ]]; then
  echo "==> Everything is up to date"
  exit 0
fi

git add -- flake.lock _sources
# Pathspec limits the commit to these files even if other changes are staged.
git commit -m "chore: update dependencies" -- flake.lock _sources
echo "==> Committed dependency updates"
