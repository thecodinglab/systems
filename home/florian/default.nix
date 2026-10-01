# cross-platform core of the user environment; platform and feature specific
# parts live next to it and are picked per host in hosts/<name>/home.nix
{
  config,
  pkgs,
  ...
}:
{
  home.stateVersion = "23.11";

  home = {
    sessionVariables = {
      LEDGER_FILE = "${config.home.homeDirectory}/finance/All.journal";
      TERMINAL_BACKGROUND_TRANSPARENT = "1";

      # the user_florian age key lives in 1password instead of on disk; sops
      # still also reads a local keys.txt if one exists
      SOPS_AGE_KEY_CMD = "op read 'op://Private/SOPS Age Key/password'";
    };

    shell.enableZshIntegration = true;
    preferXdgDirectories = true;
  };

  custom = {
    fzf.enable = true;
    tmux.enable = true;
    git.enable = true;
    theme-switcher.enable = true;
    neovim.enable = true;

    zsh.enable = true;
    ghostty.enable = true;
  };

  stylix.enable = true;

  programs = {
    bat.enable = true;
    btop.enable = true;
    yazi = {
      enable = true;
      shellWrapperName = "yy";
    };

    direnv = {
      enable = true;
      enableZshIntegration = true;

      nix-direnv.enable = true;
    };

    atuin = {
      enable = true;
      enableZshIntegration = true;

      flags = [ "--disable-ai" ];

      daemon.enable = false;

      settings = {
        keymap_mode = "vim-insert";
        enter_accept = true;
        ctrl_n_shortcuts = true;
      };
    };
  };

  home.packages = [
    pkgs.hledger
    pkgs.hledger-ui
    pkgs.hledger-web

    # Utilities
    pkgs.openssl
    pkgs.jq
    pkgs.zip
    pkgs.unzip

    # AI
    pkgs.claude-code
    pkgs.codex

    # Build Tools
    pkgs.gnumake
    pkgs.cmake

    # Git
    pkgs.git
    pkgs.git-crypt
    pkgs.gh
    pkgs.glab
    pkgs.sops

    # C/C++
    pkgs.gcc

    # Golang
    pkgs.go
    pkgs.gotools

    # Rust
    pkgs.cargo
    pkgs.rustfmt
    pkgs.rust-analyzer

    # Haskell
    pkgs.ghc
    pkgs.cabal-install
    pkgs.haskell-language-server

    # JavaScript
    pkgs.nodejs
    pkgs.bun

    # Writing
    pkgs.texliveFull
    pkgs.typst
  ];

  fonts.fontconfig.enable = true;
}
