{ config, pkgs, lib, ... }:
let
  basePackages = with pkgs;[
    # Desktop Applications
    _1password-gui
    spotify
    obsidian
    signal-desktop
  ];

  devPackages = with pkgs;[
    # Desktop Applications
    staruml
    smartgithg

    # CLI
    openssl
    vifm
    jq
    zip
    unzip

    # AI
    ollama

    # Build Tools
    gnumake
    cmake

    # Git
    git
    git-crypt
    gh
    glab

    # C/C++
    gcc

    # Golang
    go
    gopls
    gotools

    # Rust
    cargo
    rust-analyzer

    # Haskell
    ghc
    cabal-install
    haskell-language-server

    # JavaScript
    nodejs

    # Latex
    texliveFull
    texlab
  ];

  gamingPackages = with pkgs;[
    steam
    prismlauncher
  ];
in
{
  imports = [
    ../../modules/home-manager/direnv
    ../../modules/home-manager/fzf
    ../../modules/home-manager/git
    ../../modules/home-manager/kitty
    ../../modules/home-manager/sioyek
    ../../modules/home-manager/tmux
    ../../modules/home-manager/zathura
    ../../modules/home-manager/zsh

    ../../modules/home-manager/bspwm
    ../../modules/home-manager/clipcat
  ];

  options = {
    programs.default = {
      enable = lib.mkEnableOption "enable default packages";
      enableDevelopment = lib.mkEnableOption "enable development packages";
      enableGaming = lib.mkEnableOption "enable gaming packages";
    };
  };

  config = {
    home.stateVersion = "23.11";

    home.packages = lib.mkIf config.programs.default.enable (lib.mkMerge [
      basePackages
      (lib.mkIf config.programs.default.enableDevelopment devPackages)
      (lib.mkIf config.programs.default.enableGaming gamingPackages)
    ]);
  };
}
