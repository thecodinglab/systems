{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.custom.theme-switcher;

  fzfLatte =
    "--color=fg:#4c4f69,bg:#eff1f5,hl:#d20f39,fg+:#4c4f69,bg+:#ccd0da,hl+:#d20f39"
    + " --color=info:#8839ef,prompt:#1e66f5,pointer:#dc8a78,marker:#40a02b,spinner:#fe640b,header:#40a02b";

  fzfMocha =
    "--color=fg:#cdd6f4,bg:#1e1e2e,hl:#f38ba8,fg+:#cdd6f4,bg+:#313244,hl+:#f38ba8"
    + " --color=info:#cba6f7,prompt:#89b4fa,pointer:#f5e0dc,marker:#a6e3a1,spinner:#fab387,header:#a6e3a1";

  starshipConfig =
    {
      accent,
      dim,
      success,
      error,
      vim,
      warning,
    }:
    ''
      format = "${if config.custom.zsh.hostname then "$hostname " else ""}$os $directory$character "
      right_format = "$cmd_duration$shlvl$direnv"
      add_newline = false

      [character]
      format = "$symbol"
      success_symbol = "[➜](bold ${success})"
      error_symbol = "[➜](bold ${error})"
      vimcmd_symbol = "[➜](bold ${vim})"

      [os]
      disabled = false
      style = "${dim}"

      [os.symbols]
      Macos = " "
      NixOS = " "

      [username]
      format = "$user"
      show_always = true

      [hostname]
      format = "[$hostname]($style)"
      ssh_only = false
      style = "${dim}"

      [shlvl]
      disabled = false
      format = "[$symbol]($style) "
      symbol = ""
      style = "${accent}"
      threshold = 3

      [cmd_duration]
      format = "[$duration](bold ${warning}) "
    '';

  starshipLatte = pkgs.writeText "starship-catppuccin-latte.toml" (starshipConfig {
    accent = "#1e66f5";
    dim = "#6c6f85";
    success = "#40a02b";
    error = "#d20f39";
    vim = "#8839ef";
    warning = "#df8e1d";
  });

  starshipMocha = pkgs.writeText "starship-catppuccin-mocha.toml" (starshipConfig {
    accent = "#89b4fa";
    dim = "#9399b2";
    success = "#a6e3a1";
    error = "#f38ba8";
    vim = "#cba6f7";
    warning = "#f9e2af";
  });

  zshIntegration = ''
    zmodload zsh/datetime 2>/dev/null || true
    zmodload zsh/stat 2>/dev/null || true

    __terminal_theme_preference() {
      if (( ''${+__terminal_theme_cached_mode} && EPOCHSECONDS - ''${__terminal_theme_last_check:-0} < 300 )); then
        print -r -- "$__terminal_theme_cached_mode"
        return
      fi

      local mode

      if [[ "$OSTYPE" == darwin* ]]; then
        local cache_file="''${XDG_CACHE_HOME:-$HOME/.cache}/terminal-theme-mode"
        local -a cache_mtime

        if [[ -r "$cache_file" ]] && zstat -A cache_mtime -F %s +mtime "$cache_file" 2>/dev/null && (( EPOCHSECONDS - ''${cache_mtime[1]:-0} < 300 )); then
          mode="$(<"$cache_file")"
          if [[ "$mode" == dark || "$mode" == light ]]; then
            __terminal_theme_cached_mode="$mode"
            __terminal_theme_last_check="$EPOCHSECONDS"
            print -r -- "$mode"
            return
          fi
        fi

        if [[ "$(/usr/bin/defaults read -g AppleInterfaceStyle 2>/dev/null)" == "Dark" ]]; then
          mode=dark
        else
          mode=light
        fi
        [[ -d "''${cache_file:h}" ]] && { print -r -- "$mode" >| "$cache_file" } 2>/dev/null
        __terminal_theme_cached_mode="$mode"
        __terminal_theme_last_check="$EPOCHSECONDS"
        print -r -- "$mode"
        return
      fi

      if command -v gdbus >/dev/null 2>&1; then
        local portal_scheme
        portal_scheme="$(gdbus call --session \
          --dest org.freedesktop.portal.Desktop \
          --object-path /org/freedesktop/portal/desktop \
          --method org.freedesktop.portal.Settings.Read \
          org.freedesktop.appearance color-scheme 2>/dev/null)"

        case "$portal_scheme" in
          *"uint32 1"*) mode=dark ;;
          *"uint32 2"*) mode=light ;;
        esac

        if [[ -n "$mode" ]]; then
          __terminal_theme_cached_mode="$mode"
          __terminal_theme_last_check="$EPOCHSECONDS"
          print -r -- "$mode"
          return
        fi
      fi

      if command -v gsettings >/dev/null 2>&1; then
        if [[ "$(gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null)" == *dark* ]]; then
          mode=dark
        else
          mode=light
        fi
        __terminal_theme_cached_mode="$mode"
        __terminal_theme_last_check="$EPOCHSECONDS"
        print -r -- "$mode"
        return
      fi

      __terminal_theme_cached_mode=dark
      __terminal_theme_last_check="$EPOCHSECONDS"
      print -r -- dark
    }

    __terminal_theme_apply_tmux() {
      [[ -n "$TMUX" ]] || return

      if [[ "$CATPPUCCIN_FLAVOUR" == latte ]]; then
        tmux \
          set-environment -g CATPPUCCIN_FLAVOUR "$CATPPUCCIN_FLAVOUR" \; \
          set-environment -g BAT_THEME "$BAT_THEME" \; \
          set-environment -g DELTA_FEATURES "$DELTA_FEATURES" \; \
          set-environment -g FZF_DEFAULT_OPTS "$FZF_DEFAULT_OPTS" \; \
          set-environment -g STARSHIP_CONFIG "$STARSHIP_CONFIG" \; \
          set -g status-style "fg=#4c4f69,bg=#e6e9ef" \; \
          set -g status-left "#[fg=#1e66f5,bold] #S #[default]" \; \
          set -g status-right "#[fg=#6c6f85] %Y-%m-%d #[fg=#1e66f5,bold]%H:%M " \; \
          set -g window-status-format "#[fg=#6c6f85] #I:#W " \; \
          set -g window-status-current-format "#[fg=#eff1f5,bg=#1e66f5,bold] #I:#W " \; \
          set -g window-status-style "fg=#6c6f85,bg=#e6e9ef" \; \
          set -g window-status-current-style "fg=#eff1f5,bg=#1e66f5,bold" \; \
          set -g pane-border-style "fg=#bcc0cc,bg=default" \; \
          set -g pane-active-border-style "fg=#1e66f5,bg=default" \; \
          set -g message-style "fg=#4c4f69,bg=#ccd0da" \; \
          set -g mode-style "fg=#eff1f5,bg=#df8e1d,bold" \; \
          set -g status on \; \
          refresh-client -S >/dev/null 2>&1
      else
        tmux \
          set-environment -g CATPPUCCIN_FLAVOUR "$CATPPUCCIN_FLAVOUR" \; \
          set-environment -g BAT_THEME "$BAT_THEME" \; \
          set-environment -g DELTA_FEATURES "$DELTA_FEATURES" \; \
          set-environment -g FZF_DEFAULT_OPTS "$FZF_DEFAULT_OPTS" \; \
          set-environment -g STARSHIP_CONFIG "$STARSHIP_CONFIG" \; \
          set -g status-style "fg=#cdd6f4,bg=#181825" \; \
          set -g status-left "#[fg=#89b4fa,bold] #S #[default]" \; \
          set -g status-right "#[fg=#9399b2] %Y-%m-%d #[fg=#89b4fa,bold]%H:%M " \; \
          set -g window-status-format "#[fg=#9399b2] #I:#W " \; \
          set -g window-status-current-format "#[fg=#1e1e2e,bg=#89b4fa,bold] #I:#W " \; \
          set -g window-status-style "fg=#9399b2,bg=#181825" \; \
          set -g window-status-current-style "fg=#1e1e2e,bg=#89b4fa,bold" \; \
          set -g pane-border-style "fg=#45475a,bg=default" \; \
          set -g pane-active-border-style "fg=#89b4fa,bg=default" \; \
          set -g message-style "fg=#cdd6f4,bg=#313244" \; \
          set -g mode-style "fg=#1e1e2e,bg=#f9e2af,bold" \; \
          set -g status on \; \
          refresh-client -S >/dev/null 2>&1
      fi
    }

    __terminal_theme_apply_cursor() {
      [[ "$TERM_PROGRAM" == Ghostty ]] || return

      if [[ "$CATPPUCCIN_FLAVOUR" == latte ]]; then
        printf '\e]12;#dc8a78\a'
      else
        printf '\e]12;#f5e0dc\a'
      fi
    }

    __terminal_theme_apply() {
      local mode="$(__terminal_theme_preference)"
      local changed=0

      if [[ "$mode" == light ]]; then
        export CATPPUCCIN_FLAVOUR=latte
        export BAT_THEME="Catppuccin Latte"
        export DELTA_FEATURES="catppuccin-latte"
        export FZF_DEFAULT_OPTS="${fzfLatte}"
        export STARSHIP_CONFIG="${starshipLatte}"
      else
        export CATPPUCCIN_FLAVOUR=mocha
        export BAT_THEME="Catppuccin Mocha"
        export DELTA_FEATURES="catppuccin-mocha"
        export FZF_DEFAULT_OPTS="${fzfMocha}"
        export STARSHIP_CONFIG="${starshipMocha}"
      fi

      export TERMINAL_COLOR_SCHEME="$mode"
      export NVIM_BACKGROUND="$mode"

      if [[ "$__terminal_theme_applied_mode" != "$mode" ]]; then
        changed=1
        __terminal_theme_applied_mode="$mode"
      fi

      if (( changed || ( ''${+TMUX} && ! ''${+__terminal_theme_tmux_ready} ) )); then
        __terminal_theme_apply_tmux
        __terminal_theme_tmux_ready=1
      fi

      if (( changed || ! ''${+__terminal_theme_cursor_ready} )); then
        __terminal_theme_apply_cursor
        __terminal_theme_cursor_ready=1
      fi
    }

    autoload -Uz add-zsh-hook
    add-zsh-hook precmd __terminal_theme_apply
    __terminal_theme_apply
  '';
in
{
  options.custom.theme-switcher = {
    enable = lib.mkEnableOption "system-aware Catppuccin theme switcher";
  };

  config = lib.mkIf cfg.enable {
    home.sessionVariables = {
      CATPPUCCIN_FLAVOUR = "mocha";
      BAT_THEME = "Catppuccin Mocha";
      DELTA_FEATURES = "catppuccin-mocha";
      FZF_DEFAULT_OPTS = lib.mkForce fzfMocha;
      NVIM_BACKGROUND = "dark";
      STARSHIP_CONFIG = lib.mkForce (toString starshipMocha);
      TERMINAL_COLOR_SCHEME = "dark";
    };

    programs.zsh.initContent = lib.mkIf config.custom.zsh.enable zshIntegration;

    programs.git.settings = lib.mkIf config.custom.git.enable {
      delta.features = "catppuccin-mocha";

      "delta \"catppuccin-latte\"" = {
        light = true;
        syntax-theme = "Catppuccin Latte";
      };

      "delta \"catppuccin-mocha\"" = {
        dark = true;
        syntax-theme = "Catppuccin Mocha";
      };
    };

    programs.bat.config.theme = lib.mkForce "Catppuccin Mocha";
  };
}
