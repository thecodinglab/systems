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

  xdg.configFile."ghostty/config".text = ''
    theme = catppuccin-mocha
    shell-integration = zsh

    font-family = "${config.stylix.fonts.monospace.name}"
    font-size = ${builtins.toString config.stylix.fonts.sizes.terminal}

    quit-after-last-window-closed = true

    window-padding-x = 2
    window-padding-y = 4
    window-decoration = false
    macos-titlebar-style = hidden

    auto-update = off
  '';

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
    ];
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
      pkgs.obsidian

      pkgs.hledger
      pkgs.hledger-ui
      pkgs.hledger-web

      pkgs.apple-font-sf-pro
      pkgs.apple-font-sf-compact
      pkgs.apple-font-sf-mono
      pkgs.apple-font-new-york

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
      pkgs.neovim-dev

      pkgs.exiftool
      pkgs.ffmpeg

      # Kubernetes
      pkgs.kubectl
      (pkgs.wrapHelm pkgs.kubernetes-helm { plugins = [ pkgs.kubernetes-helmPlugins.helm-diff ]; })
      pkgs.helmfile
      pkgs.k9s

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
      pkgs.bun

      # Writing
      pkgs.texliveFull
      pkgs.typst
    ]
    ++ lib.optionals pkgs.stdenv.isLinux [
      pkgs.spotify

      pkgs.signal-desktop
      pkgs.protonmail-desktop
      pkgs.helvum

      pkgs.imv
      pkgs.mpv

      pkgs.prismlauncher
    ];

  fonts.fontconfig.enable = true;
}
