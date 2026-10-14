# cross-platform core of the user environment; platform and feature specific
# parts live next to it and are picked per host in hosts/<name>/home.nix
{
  config,
  lib,
  pkgs,
  ...
}:
let
  sopsKey = pkgs.writeShellScript "sops-key" ''
    case "$1:''${SOPS_AGE_RECIPIENT-}" in
      ssh:ssh-* | ssh:) exec op read "op://Private/Personal/private key?ssh-format=openssh" ;;
      age:age1* | age:) exec op read "op://Private/SOPS Age Key/password" ;;
    esac
  '';
in
{
  home.stateVersion = "23.11";

  home = {
    sessionVariables = {
      LEDGER_FILE = "${config.home.homeDirectory}/finance/All.journal";
      TERMINAL_BACKGROUND_TRANSPARENT = "1";

      SOPS_AGE_SSH_PRIVATE_KEY_CMD = "${sopsKey} ssh";
      SOPS_AGE_KEY_CMD = "${sopsKey} age";
    };

    shell.enableZshIntegration = true;
    preferXdgDirectories = true;

    file = {
      ".claude/model-selection-report.md".source = ../../docs/ai-model-selection.md;
      ".claude/agents/openai-astra.md".source = ./claude/agents/openai-astra.md;
      ".claude/agents/openai-sol.md".source = ./claude/agents/openai-sol.md;
    };
  };

  custom = {
    fzf.enable = true;
    tmux.enable = true;
    git.enable = true;
    theme-switcher.enable = true;
    neovim.enable = true;

    zsh.enable = true;
    ghostty.enable = true;

    claude-code = {
      enable = true;
      context = ./claude/CLAUDE.md;

      settings = {
        permissions.defaultMode = "bypassPermissions";
        skipDangerousModePermissionPrompt = true;
        skipAutoPermissionPrompt = true;
        skipWorkflowUsageWarning = true;

        tui = "fullscreen";
        editorMode = "vim";
        theme = "dark";
        agentPushNotifEnabled = false;

        autoMemoryEnabled = false;
        env = {
          CLAUDE_CODE_DISABLE_AUTO_MEMORY = "1";
          CLAUDE_CODE_DISABLE_ORG_MEMORY = "1";

          DISABLE_TELEMETRY = "1";
          DISABLE_ERROR_REPORTING = "1";
        };

        effortLevel = "high";

        enabledPlugins."frontend-design@claude-plugins-official" = true;
      };

      proxy = {
        enable = true;
        url = lib.mkDefault "http://192.168.48.124:8317"; # macmini
        apiKeyCommand = lib.mkDefault ''op read "op://Private/CLIProxyAPI/password"'';
      };
    };
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
