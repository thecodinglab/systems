{
  config,
  pkgs,
  lib,
  systemName,
  ...
}:
let
  isLinux = lib.hasSuffix "linux" systemName;
in
{
  home.stateVersion = "23.11";

  home = {
    username = "florian";
    homeDirectory = if pkgs.stdenv.isDarwin then "/Users/florian" else "/home/florian";

    sessionVariables = {
      LEDGER_FILE = "${config.home.homeDirectory}/finance/All.journal";
    };

    shell.enableZshIntegration = true;
  };

  xdg.mimeApps.enable = isLinux;

  custom = {
    fzf.enable = true;
    tmux.enable = true;
    chromium.enable = isLinux;
    git.enable = true;

    hyprland.enable = isLinux;
    zsh.enable = true;
    zathura.enable = true;
    ghostty.enable = true;
  };

  xdg.mimeApps.defaultApplications = {
    "x-scheme-handler/http" = [ "helium.desktop" ];
    "x-scheme-handler/https" = [ "helium.desktop" ];
    "x-scheme-handler/chrome" = [ "helium.desktop" ];

    "text/html" = [ "helium.desktop" ];
    "application/x-extension-htm" = [ "helium.desktop" ];
    "application/x-extension-html" = [ "helium.desktop" ];
    "application/x-extension-shtml" = [ "helium.desktop" ];
    "application/xhtml+xml" = [ "helium.desktop" ];
    "application/x-extension-xhtml" = [ "helium.desktop" ];
    "application/x-extension-xht" = [ "helium.desktop" ];

    "application/pdf" = [ "org.pwmt.zathura.desktop" ];
    "application/oxps" = [ "org.pwmt.zathura.desktop" ];
    "application/epub+zip" = [ "org.pwmt.zathura.desktop" ];
    "application/x-fictionbook" = [ "org.pwmt.zathura.desktop" ];
  };

  stylix.enable = true;

  programs = {
    bat.enable = true;
    btop.enable = true;
    sioyek.enable = true;
    yazi.enable = true;

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

  home.packages = [
    pkgs.obsidian

    pkgs.hledger
    pkgs.hledger-ui
    pkgs.hledger-web

    pkgs.apple-font-sf-pro
    pkgs.apple-font-sf-compact
    pkgs.apple-font-sf-mono
    pkgs.apple-font-new-york

    # Utilities
    pkgs.openssl
    pkgs.jq
    pkgs.zip
    pkgs.unzip
    pkgs.ollama

    # Coding
    pkgs.neovide
    pkgs.zed-editor
    pkgs.beekeeper-studio
    pkgs.claude-code

    (pkgs.neovim-dev.extend {
      plugins.ledger.enable = true;

      plugins.lsp.servers.texlab.enable = true;
      plugins.vimtex = {
        enable = true;
        texlivePackage = pkgs.texlive.combined.scheme-full;
        settings.view_method = if pkgs.stdenv.isDarwin then "sioyek" else "zathura";
      };

      plugins.markdown-preview.enable = true;

      plugins.obsidian = {
        enable = true;
        settings = {
          legacy_commands = false;

          workspaces = [
            {
              name = "singularity";
              path = "~/vaults/singularity";
            }
          ];

          completion.blink = true;

          notes_subdir = "02 - Fleeting/";

          daily_notes = {
            folder = "04 - Daily/";
            date_format = "%Y-%m-%d";
          };

          templates = {
            subdir = "99 - Meta/00 - Templates/";
            date_format = "%Y-%m-%d";
            time_format = "%H:%M";
          };

          note_id_func = ''
            function(title)
              local suffix = ""
              if title ~= nil then
                suffix = title:gsub(" ", "-"):gsub("[^A-Za-z0-9-]", ""):lower()
              else
                for _ = 1, 4 do
                  suffix = suffix .. string.char(math.random(65, 90))
                end
              end
              return os.date("%Y%m%d%H%M") .. "-" .. suffix
            end
          '';

          follow_url_func = ''
            function(url)
              vim.ui.open(url)
            end
          '';
        };
      };
    })

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
    pkgs.texlive.combined.scheme-full
    pkgs.typst

    # Minecraft
    pkgs.prismlauncher
    pkgs.jdk
  ]
  ++ lib.optionals isLinux [
    pkgs.helium
    pkgs.spotify
    pkgs.slack

    pkgs.postman

    pkgs.helvum
    pkgs.fragments
    pkgs.obs-studio

    pkgs.imv
    pkgs.mpv

    pkgs.chatterino7
  ];

  fonts.fontconfig.enable = true;
}
