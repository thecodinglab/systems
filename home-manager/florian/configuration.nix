{
  config,
  outputs,
  pkgs,
  lib,
  ...
}:
{
  home.stateVersion = "23.11";

  nixpkgs.overlays = [
    outputs.overlays.additions
    outputs.overlays.modifications
  ];

  home = {
    username = "florian";
    homeDirectory = if pkgs.stdenv.isDarwin then "/Users/florian" else "/home/florian";

    sessionVariables = {
      LEDGER_FILE = "${config.home.homeDirectory}/finance/All.journal";
    };
  };

  custom = {
    fzf.enable = true;
    tmux.enable = true;
    chromium.enable = pkgs.stdenv.isLinux;
    kitty.enable = true;
    git.enable = true;

    hyprland.enable = pkgs.stdenv.isLinux;
    zsh.enable = true;
    zathura.enable = true;

    unfree = [
      "1password"
      "1password-cli"
      "spotify"
      "obsidian"
      "postman"
      "lens-desktop"
    ] ++ lib.optionals pkgs.stdenv.isDarwin [ "raycast" ];
  };

  stylix.enable = true;

  programs = {
    bat.enable = true;
    btop.enable = true;
    sioyek.enable = true;

    direnv = {
      enable = true;
      enableZshIntegration = true;

      nix-direnv.enable = true;
    };

    atuin = {
      enable = true;
      enableZshIntegration = true;

      settings = {
        keymap_mode = "vim-insert";
        enter_accept = true;
        ctrl_n_shortcuts = true;
      };
    };
  };

  home.packages =
    [
      pkgs.spotify
      pkgs.obsidian

      pkgs.hledger
      pkgs.hledger-ui
      pkgs.hledger-web

      pkgs.fonts.apple-font-sf-pro
      pkgs.fonts.apple-font-sf-compact
      pkgs.fonts.apple-font-sf-mono
      pkgs.fonts.apple-font-new-york

      # Utilities
      pkgs._1password
      pkgs.openssl
      pkgs.vifm
      pkgs.jq
      pkgs.zip
      pkgs.unzip
      # FIXME: current version of ollama has invalid fixed output hash
      # pkgs.ollama
      pkgs.postman
      pkgs.neovim.dev

      pkgs.exiftool
      pkgs.ffmpeg

      pkgs.nix-output-monitor
      pkgs.npins

      # Kubernetes
      pkgs.kubectl
      pkgs.k9s
      pkgs.lens

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
      pkgs.gopls
      pkgs.gotools

      # Rust
      pkgs.cargo
      pkgs.rust-analyzer

      # Haskell
      pkgs.ghc
      pkgs.cabal-install
      pkgs.haskell-language-server

      # JavaScript
      pkgs.nodejs

      # Writing
      pkgs.texliveFull
      pkgs.texlab
      pkgs.typst

    ]
    ++ lib.optionals pkgs.stdenv.isLinux [
      pkgs.signal-desktop
      pkgs.protonmail-desktop
      pkgs.helvum

      pkgs.imv
      pkgs.mpv

      pkgs.prismlauncher
    ]
    ++ lib.optionals pkgs.stdenv.isDarwin [ pkgs.raycast ];

  fonts.fontconfig.enable = true;
}
