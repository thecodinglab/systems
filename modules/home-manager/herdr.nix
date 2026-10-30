{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.custom.herdr;
  herdr = lib.getExe config.programs.herdr.package;
  agentLabel = "org.nix-community.home.herdr";
  inherit (pkgs.stdenv.hostPlatform) isDarwin;

  # Smart pane switching with awareness of Vim splits, like vim-tmux-navigator:
  # vim, fzf and a nested tmux get the key, nvim hands over to herdr at its
  # edge.
  # Custom commands run from the server, whose environment may be bare
  # (launchd), so only rely on the variables herdr passes.
  navigate = pkgs.writeShellApplication {
    name = "herdr-navigate";
    runtimeInputs = [ pkgs.jq ];
    text = ''
      direction=$1
      key=$2
      herdr=''${HERDR_BIN_PATH:-herdr}
      pane=$HERDR_ACTIVE_PANE_ID

      if "$herdr" pane process-info --pane "$pane" | jq -e '
        .result.process_info.foreground_processes
        | any(.name | test("^(g?(view|l?n?vim?x?|fzf)(diff)?|tmux)$"))
      ' >/dev/null; then
        "$herdr" pane send-keys "$pane" "$key"
      else
        "$herdr" pane focus --direction "$direction" --pane "$pane"
      fi
    '';
  };

  # the tmux session name: tab bar entries can't name the workspace, so a status
  # command looks it up (polled, so it trails a workspace switch by up to 1s)
  workspaceName = pkgs.writeShellApplication {
    name = "herdr-workspace-name";
    runtimeInputs = [ pkgs.jq ];
    text = ''
      "''${HERDR_BIN_PATH:-herdr}" workspace get "$HERDR_ACTIVE_WORKSPACE_ID" |
        jq -r .result.workspace.label
    '';
  };

  # devtools opens worktrees as herdr workspaces when it runs inside herdr;
  # popups get the server's environment, so bring along what it calls
  devtools =
    command:
    lib.getExe (
      pkgs.writeShellApplication {
        name = "herdr-devtools-${command}";
        runtimeInputs = [
          pkgs.devtools
          pkgs.fzf
          pkgs.git
        ];
        text = ''
          exec devtools ${command}
        '';
      }
    );

  navigateKey = key: direction: {
    key = "ctrl+${key}";
    type = "shell";
    command = "${lib.getExe navigate} ${direction} ctrl+${key}";
    description = "focus pane ${direction} (vim aware)";
  };
in
{
  options.custom.herdr = {
    enable = lib.mkEnableOption "enable herdr";
  };

  config = lib.mkIf cfg.enable {
    programs.herdr = {
      enable = true;
      settings = {
        onboarding = false;

        # follows the system appearance like the theme switcher does for tmux;
        # the colors are the ones the theme switcher gives the tmux status
        # line and borders (panes never get a background, so terminal
        # transparency/blur shows through either way)
        theme = {
          name = "catppuccin";
          auto_switch = true;
          dark_name = "catppuccin";
          light_name = "catppuccin-latte";
          custom = {
            dark = {
              accent = "#89b4fa";
              # status line, also behind dialogs
              panel_bg = "#181825";
              # inactive tabs blend into the status line, input fields stay
              # visible in dialogs
              surface0 = "#1e1e2e";
              # the status entries, like the date in tmux
              overlay1 = "#9399b2";
            };
            light = {
              accent = "#1e66f5";
              panel_bg = "#e6e9ef";
              surface0 = "#eff1f5";
              overlay1 = "#6c6f85";
            };
          };
        };

        terminal = {
          default_shell = lib.getExe pkgs.zsh;
          # same as the tmux default-command
          shell_mode = "non_login";
        };

        ui = {
          # create tabs right away, like tmux windows
          prompt_new_tab_name = false;

          # look like tmux: status line at the bottom, splitters only between
          # panes and the sidebar out of the way (prefix+b brings it back)
          tab_bar_position = "bottom";
          pane_gaps = false;
          pane_borders = "auto";
          pane_outer_borders = false;
          pane_scrollbars = false;
          sidebar_start_collapsed = true;
          sidebar_collapsed_mode = "hidden";

          tab_bar_right = [
            {
              type = "command";
              command = lib.getExe workspaceName;
              interval_seconds = 1;
            }
            { type = "hostname"; }
            {
              type = "datetime";
              format = "%Y-%m-%d";
            }
            {
              type = "datetime";
              format = "%H:%M";
            }
          ];
        };

        # herdr defaults plus the tmux bindings, so both work the same way
        keys = {
          prefix = "ctrl+space";

          # tmux: `%` side by side, `"` stacked
          split_vertical = [
            "prefix+v"
            "prefix+percent"
          ];
          split_horizontal = [
            "prefix+minus"
            "prefix+double_quote"
          ];

          rename_tab = [
            "prefix+shift+t"
            "prefix+comma"
          ];
          close_tab = [
            "prefix+shift+x"
            "prefix+ampersand"
          ];
          last_pane = "prefix+semicolon";

          # tmux customPaneNavigationAndResize: prefix+hjkl are herdr defaults
          resize_pane_left = "prefix+H";
          resize_pane_down = "prefix+J";
          resize_pane_up = "prefix+K";
          resize_pane_right = "prefix+L";

          # tmux session keys for workspaces
          previous_workspace = "prefix+(";
          next_workspace = "prefix+)";
          rename_workspace = [
            "prefix+shift+w"
            "prefix+$"
          ];
          detach = [
            "prefix+q"
            "prefix+d"
          ];

          # prefix+o and prefix+s pick a project / workspace, see below
          settings = "prefix+shift+s";
          open_notification_target = "prefix+shift+o";

          command = [
            {
              key = "prefix+o";
              type = "popup";
              command = devtools "pick";
              description = "devtools pick";
              width = "90%";
              height = "80%";
            }
            {
              key = "prefix+s";
              type = "popup";
              command = devtools "sessions";
              description = "devtools sessions";
              width = "90%";
              height = "80%";
            }
            (navigateKey "h" "left")
            (navigateKey "j" "down")
            (navigateKey "k" "up")
            (navigateKey "l" "right")
          ];
        };
      };
    };

    # an ssh login gets its own security session, which can't see the keychain
    # unlocked by the gui login (no codesign etc.); a server started by launchd
    # lives in the gui session and so do all of its panes
    launchd.agents.herdr = lib.mkIf isDarwin {
      enable = true;
      config = {
        ProgramArguments = [
          herdr
          "server"
        ];
        RunAtLoad = true;
        KeepAlive = true;
        ProcessType = "Interactive";
        # launchd hands agents a bare environment and panes inherit it
        EnvironmentVariables = {
          SHELL = lib.getExe pkgs.zsh;
          LANG = "en_US.UTF-8";
        };
      };
    };

    # never let an ssh login start the server, it would be stuck in the ssh
    # security session; launching or attaching the ui and `herdr server` may
    # start one, every other command only talks to a running server
    programs.zsh.initContent = lib.mkIf (isDarwin && config.custom.zsh.enable) ''
      herdr() {
        local starts=0 session=''${HERDR_SESSION:-}
        case $1 in
          "") starts=1 ;;
          --session) (( $# <= 2 )) && starts=1 session=$2 ;;
          session) [[ $2 == attach ]] && starts=1 session=$3 ;;
          server) (( $# == 1 )) && starts=1 ;;
        esac
        if (( starts )) && [[ -n $SSH_CONNECTION && -z $HERDR_ENV ]] \
          && ! command env ''${session:+HERDR_SESSION=$session} herdr status server 2>/dev/null | grep -q 'status: running'; then
          print -u2 "herdr: no server running, refusing to start one from ssh (the keychain would be locked)"
          print -u2 "herdr: start it in the gui session: launchctl kickstart gui/$UID/${agentLabel}"
          return 1
        fi
        command herdr "$@"
      }
    '';

    home.packages = [ pkgs.devtools ];
  };
}
