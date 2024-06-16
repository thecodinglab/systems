{ config, pkgs, lib, ... }:
let
  basePackages = lib.mkMerge [
    [
      # Desktop Applications
      pkgs.spotify
      pkgs.obsidian

      pkgs.apple-font-sf-pro
      pkgs.apple-font-sf-compact
      pkgs.apple-font-sf-mono
      pkgs.apple-font-sf-new-york
    ]
    (lib.mkIf pkgs.stdenv.isLinux [
      pkgs.signal-desktop
      pkgs.protonmail-desktop
      pkgs.helvum
    ])
    (lib.mkIf pkgs.stdenv.isDarwin [
      pkgs.raycast
    ])
  ];

  devPackages = lib.mkMerge [
    (with pkgs; [
      # Utilities
      _1password
      openssl
      vifm
      jq
      zip
      unzip
      ollama

      nix-output-monitor
      npins

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
    ])
    (lib.mkIf pkgs.stdenv.isLinux [
      # Desktop Applications
      pkgs.staruml
    ])
  ];

  photographyPackages = lib.mkMerge [
    [
      pkgs.exiftool
      pkgs.ffmpeg
      pkgs.mpv

      pkgs.darktable
    ]
    (lib.mkIf pkgs.stdenv.isLinux [
      pkgs.imv
    ])
  ];

  gamingPackages = [
    pkgs.steam
    pkgs.prismlauncher
  ];
in
{
  imports = [
    ../../themes/nord/modules/home-manager
    ../../themes/catppuccin/modules/home-manager

    ../../modules/home-manager/btop
    ../../modules/home-manager/direnv
    ../../modules/home-manager/fzf
    ../../modules/home-manager/git
    ../../modules/home-manager/kitty
    ../../modules/home-manager/sioyek
    ../../modules/home-manager/tmux
    ../../modules/home-manager/wallpaper
    ../../modules/home-manager/zathura
    ../../modules/home-manager/zsh

    ../../modules/home-manager/hyprland
  ];

  options = {
    programs.default = {
      enable = lib.mkEnableOption "enable default packages";
      enableDevelopment = lib.mkEnableOption "enable development packages";
      enablePhotography = lib.mkEnableOption "enable photography packages";
      enableGaming = lib.mkEnableOption "enable gaming packages";
    };
  };

  config = {
    home.stateVersion = "23.11";

    catppuccin.enable = true;

    home.packages = lib.mkIf config.programs.default.enable (lib.mkMerge [
      basePackages
      (lib.mkIf config.programs.default.enableDevelopment devPackages)
      (lib.mkIf config.programs.default.enablePhotography photographyPackages)
      (lib.mkIf config.programs.default.enableGaming gamingPackages)
    ]);

    fonts.fontconfig.enable = true;
  };
}
