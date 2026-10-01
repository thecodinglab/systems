# local

Escape hatch for per-machine experiments. This directory is the flake input
`local` and stays empty in the repository.

Put experiments in `~/.config/systems-local` instead (or point `LOCAL_DIR` at
another directory); the Makefile then passes
`--override-input local path:<dir>`, which does not touch `flake.lock`.

For a host `<name>` (as in `hosts/<name>`):

- `<name>.nix` is added to the system modules (nix-darwin or NixOS)
- `<name>-home.nix` is added to `home-manager.users.florian`; only hosts with a
  `hosts/<name>/home.nix` (the ones with that user: macbookpro, macmini,
  desktop) accept it, anywhere else evaluation stops with an error

Never commit these files. Once an experiment sticks, move it to
`hosts/<name>/` (or a module) and delete it from the local directory.
