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

    shell.enableZshIntegration = true;
  };

  xdg.configFile."ghostty/config".text = ''
    theme = dark:catppuccin-mocha,light:catppuccin-latte
    shell-integration = zsh

    font-family = "${config.stylix.fonts.monospace.name}"
    font-size = ${builtins.toString config.stylix.fonts.sizes.terminal}

    quit-after-last-window-closed = true

    window-padding-x = 2
    window-padding-y = 4

    auto-update = off
  '';

  xdg.mimeApps.enable = pkgs.stdenv.isLinux;

  custom = {
    fzf.enable = true;
    tmux.enable = true;
    chromium.enable = pkgs.stdenv.isLinux;
    git.enable = true;

    hyprland.enable = pkgs.stdenv.isLinux;
    zsh.enable = true;
    zathura.enable = true;
    zen-browser.enable = true;

    unfree = [
      "1password"
      "1password-cli"
      "spotify"
      "slack"
      "obsidian"
      "postman"
    ];
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
      pkgs.openssl
      pkgs.jq
      pkgs.zip
      pkgs.unzip
      pkgs.ollama

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
            dir = "~/vaults/singularity";

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
                if vim.fn.executable("xdg-open") == 1 then
                  vim.fn.jobstart({ "xdg-open", url })
                  return
                end

                if vim.fn.executable("open") == 1 then
                  vim.fn.jobstart({ "open", url })
                  return
                end

                vim.notify("unable to open link: no tool found", vim.log.levels.ERROR)
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
      pkgs.texliveFull
      pkgs.typst

      # Minecraft
      pkgs.prismlauncher
      pkgs.jdk
    ]
    ++ lib.optionals pkgs.stdenv.isLinux [
      pkgs._1password
      pkgs.spotify
      pkgs.slack

      pkgs.postman

      pkgs.ghostty
      pkgs.helvum
      pkgs.fragments
      pkgs.obs-studio

      pkgs.imv
      pkgs.mpv
    ];

  fonts.fontconfig.enable = true;
}
