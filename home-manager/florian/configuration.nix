{
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
    homeDirectory = "/home/florian";
  };

  custom = {
    catppuccin.enable = true;
    fzf.enable = true;
    tmux.enable = true;
    chromium.enable = true;
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
    ];
  };

  programs = {
    bat.enable = true;
    btop.enable = true;
    sioyek.enable = true;

    direnv = {
      enable = true;
      enableZshIntegration = true;

      nix-direnv.enable = true;
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
      pkgs.ollama
      pkgs.postman

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

      pkgs.darktable

      pkgs.imv
      pkgs.mpv

      pkgs.prismlauncher
    ]
    ++ lib.optionals pkgs.stdenv.isDarwin [
      pkgs.raycast
      pkgs.tableplus
    ];

  fonts.fontconfig.enable = true;
}
