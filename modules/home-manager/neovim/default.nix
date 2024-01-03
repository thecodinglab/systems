{ lib, pkgs, config, ... }: {
  programs.neovim = {
    enable = true;
    withNodeJs = true; # required for copilot
  };

  # NOTE: the neovim config is cloned manually here, as otherwise it would be
  #       symlinked into the home directory, which makes it read-only and
  #       therefore does not allow to quickly try out something. in the future i
  #       want to switch to a completely nix managed neovim configuration.
  home.activation.cloneNeovimConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    DIR="${config.home.homeDirectory}/.config/nvim"

    if [ -d "$DIR" ]; then
      cd "$DIR"
      $DRY_RUN_CMD ${pkgs.git}/bin/git pull --ff-only
    else
      $DRY_RUN_CMD ${pkgs.git}/bin/git clone "https://github.com/thecodinglab/neovim-config.git" "$DIR"
    fi
  '';
}
