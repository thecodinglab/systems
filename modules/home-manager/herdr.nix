{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.custom.herdr;
  agentLabel = "org.nix-community.home.herdr";
  inherit (pkgs.stdenv.hostPlatform) isDarwin;
  palette = import ./theme/palette.nix;

  # The server only runs as the launchd agent below. An ssh login gets its own
  # security session, which can't see the keychain unlocked by the gui login
  # (no codesign etc.), and a server started by launchd lives in the gui
  # session with all of its panes. A client that finds no server starts one
  # from its own executable, so no shell guard can stop that; the server
  # itself refuses to start without the marker only the agent sets. It drops
  # the marker right away so panes don't pass it on (a tmux in a pane outlives
  # the server). A handoff import is spawned by the running server and keeps
  # its context, as upstream does for the macOS service context.
  launchMarker = "HERDR_LAUNCHD_AGENT";
  server =
    if isDarwin then
      pkgs.herdr.overrideAttrs (old: {
        postPatch = (old.postPatch or "") + ''
          substituteInPlace src/server/headless/bootstrap.rs \
            --replace-fail \
              'let handoff_import = args.get(2).map(String::as_str) == Some("--handoff-import");' \
              'let handoff_import = args.get(2).map(String::as_str) == Some("--handoff-import");
              let launched_by_agent = std::env::var_os("${launchMarker}").is_some();
              std::env::remove_var("${launchMarker}");
              if !handoff_import && !launched_by_agent {
                  eprintln!("error: this herdr server only runs as the launchd agent ${agentLabel}");
                  if std::env::var_os("SSH_CONNECTION").is_some() {
                      eprintln!("an ssh login has its own security session, which cannot see the keychain");
                  }
                  eprintln!(
                      "start it in the gui session: launchctl kickstart gui/{}/${agentLabel}",
                      unsafe { libc::getuid() }
                  );
                  std::process::exit(1);
              }'
        '';
      })
    else
      pkgs.herdr;
  herdr = lib.getExe server;

  # Panes and popups get herdr's own agent link as SSH_AUTH_SOCK, and a
  # server prefers what that link pointed to before over the SSH_AUTH_SOCK
  # it inherits (src/platform/ssh_agent.rs). A server stopped by launchd
  # leaves the link behind, so the next one would keep the agent from before
  # the forwarded agents' proxy (see the ssh module). Drop it before a fresh
  # start; never under a running server, e.g. one a handoff left behind.
  agentLink = "${config.home.homeDirectory}/.config/herdr/herdr.sock.agent";
  startWithAgentProxy = pkgs.writeShellApplication {
    name = "herdr-server";
    text = ''
      if [[ $(${herdr} status server 2>/dev/null) != *"status: running"* ]]; then
        rm -f ${lib.escapeShellArg agentLink}
      fi
      exec ${herdr} server
    '';
  };

  # Launching or attaching the ui with no server running would start one,
  # which the server refuses only after the client waited 15s for it. Refuse
  # up front, in every shell and over ssh, and say how to start it instead.
  # Every other command only talks to a running server, `herdr server` runs
  # into the refusal itself. Panes get the server's own path in
  # HERDR_BIN_PATH, so the custom commands below skip the wrapper.
  guarded = pkgs.symlinkJoin {
    name = "${server.pname}-launchd-only-${server.version}";
    paths = [ server ];
    meta.mainProgram = "herdr";
    postBuild = ''
      ln -sf ${lib.getExe guard} $out/bin/herdr
    '';
  };
  guard = pkgs.writeShellApplication {
    name = "herdr";
    text = ''
      starts=0 session=
      case ''${1-} in
        "") starts=1 ;;
        --session) (( $# <= 2 )) && starts=1 session=''${2-} ;;
        session) [[ ''${2-} == attach ]] && starts=1 session=''${3-} ;;
      esac
      [[ -n $session ]] && export HERDR_SESSION=$session
      if (( starts )) && [[ -z ''${HERDR_ENV-} ]] \
        && [[ $(${herdr} status server 2>/dev/null) != *"status: running"* ]]; then
        echo >&2 "herdr: no server running, and only launchd starts one (from ssh it could not see the keychain)"
        echo >&2 "herdr: start it in the gui session: launchctl kickstart gui/$UID/${agentLabel}"
        exit 1
      fi
      exec ${herdr} "$@"
    '';
  };

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

  # popups get the server's bare launchd environment, so not the fzf colours
  # of the shell either; devtools' own switcher draws in the terminal's
  # palette, its agent and machine pickers are still fzf
  fzfOptions = lib.optionalString (
    config.home.sessionVariables ? FZF_DEFAULT_OPTS
  ) "export FZF_DEFAULT_OPTS=${lib.escapeShellArg config.home.sessionVariables.FZF_DEFAULT_OPTS}";

  # devtools opens worktrees as herdr workspaces when it runs inside herdr,
  # and takes the pane under a popup as where you are; popups get the
  # server's environment, so bring along what it calls
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
          ${fzfOptions}
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
      package = if isDarwin then guarded else server;
      settings = {
        onboarding = false;

        # Its "terminal" theme draws in the terminal's own colours, so it
        # switches with ghostty, see the ghostty module. The grounds it can't
        # take from those come from the same palette, one set per appearance:
        # the status line (also behind dialogs) a step off the ground with
        # inactive tabs and input fields on the ground itself, its entries in
        # the comment grey like the tmux status line, and the row under the
        # cursor raised rather than filled in that grey, which leaves the ink
        # on it under 3:1.
        theme = {
          name = "terminal";
          auto_switch = true;
          dark_name = "terminal";
          light_name = "terminal";
          custom = lib.mapAttrs (_: colors: {
            accent = "#${colors.base0D}";
            panel_bg = "#${colors.base01}";
            surface0 = "#${colors.base00}";
            overlay1 = "#${colors.base03}";
            active_row_bg = "#${colors.base02}";
          }) (removeAttrs palette [ "selection" ]);
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

          # worktrees belong to devtools (prefix+f below), so none of herdr's
          # own, which live in a layout of their own under ~/.herdr/worktrees
          new_worktree = "";
          open_worktree = "";
          remove_worktree = "";

          # prefix+o and prefix+s pick a project / workspace, prefix+f starts a
          # feature worktree, see below
          settings = "prefix+shift+s";
          open_notification_target = "prefix+shift+o";

          command = [
            # the devtools switcher: every worktree, switch, start a feature
            # by typing its name, merge one into main
            {
              key = "prefix+o";
              type = "popup";
              command = devtools "pick";
              description = "devtools: switch worktree";
              width = "90%";
              height = "80%";
            }
            # the same on the open workspaces
            {
              key = "prefix+s";
              type = "popup";
              command = devtools "sessions";
              description = "devtools: switch workspace";
              width = "90%";
              height = "80%";
            }
            # the same, ready to name a feature in the current project
            {
              key = "prefix+f";
              type = "popup";
              command = devtools "work";
              description = "devtools: new feature";
              width = "90%";
              height = "50%";
            }
            (navigateKey "h" "left")
            (navigateKey "j" "down")
            (navigateKey "k" "up")
            (navigateKey "l" "right")
          ];
        };
      };
    };

    # the only place the server starts, see `server` above
    launchd.agents.herdr = lib.mkIf isDarwin {
      enable = true;
      config = {
        ProgramArguments =
          if config.custom.ssh.forwardedAgents.enable then
            [ (lib.getExe startWithAgentProxy) ]
          else
            [
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
          # forwarded ssh agents, see the ssh module
          SSH_AUTH_SOCK = lib.mkIf config.custom.ssh.forwardedAgents.enable config.custom.ssh.forwardedAgents.socket;
          ${launchMarker} = "1";
        };
      };
    };

    home.packages = [ pkgs.devtools ];
  };
}
