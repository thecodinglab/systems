{
  config,
  pkgs,
  lib,
  ...
}:
{
  options.custom.hyprland = {
    enable = lib.mkEnableOption "enable hyprland";

    # the session-wide versions of the accessibility switches on a mac,
    # handed to both the compositor and the shell so the two never disagree
    accessibility = {
      reduceMotion = lib.mkEnableOption "fades in place of windows and workspaces sliding or zooming";
      reduceTransparency = lib.mkEnableOption "opaque terminals and shell surfaces instead of frosted ones";
      increaseContrast = lib.mkEnableOption "stronger window outlines and shell hairlines";
    };
  };

  config =
    let
      mod = "SUPER";
      monitors = {
        left = "DP-7";
        center = "DP-4";
        right = "DP-6";
      };

      a11y = config.custom.hyprland.accessibility;
      colors = config.lib.stylix.colors;

      # the shell's 4-unit grid, see `Theme.px` in the shell: a unit is a
      # pixel at a 10pt session font, times the shell's own 1.25 scale.
      # Gaps and corners are drawn on it, so the windows and the notch
      # hanging over them are measured with the same ruler.
      px = units: builtins.floor (units * config.stylix.fonts.sizes.desktop / 10 * 1.25 + 0.5);

      # One set of curves and animations for the compositor and the shell,
      # which reads them by hyprland's names (`Config.curves`,
      # `Config.animations`), so the notch moves exactly like the windows
      # around it.
      motion = {
        curves = {
          easeOutQuint = {
            type = "bezier";
            points = [
              [
                0.23
                1
              ]
              [
                0.32
                1
              ]
            ];
          };
          easeOutExpo = {
            type = "bezier";
            points = [
              [
                0.16
                1
              ]
              [
                0.3
                1
              ]
            ];
          };
          almostLinear = {
            type = "bezier";
            points = [
              [
                0.5
                0.5
              ]
              [
                0.75
                1
              ]
            ];
          };
          linear = {
            type = "bezier";
            points = [
              [
                0
                0
              ]
              [
                1
                1
              ]
            ];
          };
          quick = {
            type = "bezier";
            points = [
              [
                0.15
                0
              ]
              [
                0.1
                1
              ]
            ];
          };

          # damping ratio ~0.85, under 1% overshoot: windows arrive rather
          # than bounce, they are opened too often to be performed at
          soft = {
            type = "spring";
            mass = 1;
            stiffness = 200;
            dampening = 24;
          };
          # ~0.95, for scrolling columns around
          snappy = {
            type = "spring";
            mass = 1;
            stiffness = 320;
            dampening = 34;
          };
        };

        # Order matters to hyprland: a leaf set after its parent keeps its own
        # values. With reduced motion nothing slides or zooms any more: windows
        # and workspaces cross-fade in place, the way a mac swaps a slide for a
        # dissolve.
        animations =
          let
            anim =
              leaf: speed: curve: extra:
              { inherit leaf speed curve; } // extra;
            still = {
              enabled = !a11y.reduceMotion;
            };
            fadeWhenReduced = style: { style = if a11y.reduceMotion then "fade" else style; };
          in
          [
            (anim "global" 8 "default" { })

            (anim "windows" 4.5 "soft" still)
            (anim "windowsIn" 4 "soft" (still // { style = "popin 85%"; }))
            (anim "windowsOut" 1.5 "linear" (still // { style = "popin 90%"; }))
            (anim "windowsMove" 4 "snappy" still)

            (anim "border" 5 "easeOutQuint" { })

            (anim "fade" 3 "quick" { })
            (anim "fadeIn" 1.7 "almostLinear" { })
            (anim "fadeOut" 1.5 "almostLinear" { })

            (anim "layers" 3.8 "easeOutQuint" { })
            (anim "layersIn" 4 "easeOutQuint" { style = "fade"; })
            (anim "layersOut" 1.5 "linear" { style = "fade"; })
            (anim "fadeLayersIn" 1.8 "almostLinear" { })
            (anim "fadeLayersOut" 1.4 "almostLinear" { })

            # workspaces stack vertically, the scrolling layout runs horizontally
            (anim "workspaces" 4 "easeOutExpo" (fadeWhenReduced "slidefadevert 20%"))
            (anim "specialWorkspace" 4 "easeOutExpo" (fadeWhenReduced "slidefadevert 30%"))

            (anim "zoomFactor" 7 "quick" still)
          ];
      };

      # Windows are told apart the way a mac tells them apart: by depth, not
      # by a coloured frame. Every window gets a hairline in the palette's ink
      # and a black shadow (it falls on whatever is behind it); the one with
      # the keyboard gets a brighter line and a deeper shadow, so it reads as
      # nearer. The accent stays the shell's, where it only ever says *on* or
      # *here*.
      #
      # The focused line is ~4:1 against the desktop between windows and
      # ~3.4:1 against a terminal beside it; the others are left faint, the
      # shadow is what separates them.
      ink = alpha: "rgba(${colors.base05}${alpha})";
      hairline =
        if a11y.increaseContrast then
          {
            active = ink "cc";
            inactive = ink "59";
          }
        else
          {
            active = ink "80";
            inactive = ink "1f";
          };

      # a toast from the shell, for things that happen with nothing on screen
      # to show for it
      notify = lib.getExe pkgs.libnotify;
      hyprctl = lib.getExe' pkgs.hyprland "hyprctl";

      # What a screenshot looks like when it is taken: the shot comes out of
      # the top edge as a toast with itself for its icon, the way a mac shows
      # the thumbnail in the corner, rather than going to the clipboard with
      # nothing to say it happened. Escape out of the selection takes nothing
      # and says nothing.
      screenshot = pkgs.writers.writeBash "screenshot" ''
        set -euo pipefail

        hyprctl=${hyprctl}
        jq=${lib.getExe pkgs.jq}
        slurp=${lib.getExe pkgs.slurp}
        grim=${lib.getExe pkgs.grim}
        copy=${lib.getExe' pkgs.wl-clipboard "wl-copy"}

        case "$1" in
          # drag out a rectangle
          area) area=$($slurp) ;;
          # pick one of the windows on a visible workspace
          window) area=$($hyprctl clients -j | $jq --argjson active "$($hyprctl monitors -j | $jq -c '[.[].activeWorkspace.id]')" '.[] | select((.hidden | not) and (.workspace.id as $id | $active | contains([$id]))) | "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"' -r | $slurp) ;;
        esac

        file="$XDG_RUNTIME_DIR/screenshot.png"
        $grim -g "$area" -t png "$file"
        $copy -t image/png < "$file"

        ${notify} -a Screenshot -i "$file" -t 3000 \
          -h string:x-canonical-private-synchronous:screenshot \
          "Screenshot copied"
      '';

      # Logging out quits every app, so it is asked for twice: the first press
      # says what is about to happen, a second within a few seconds does it,
      # the way the shell's restart and shut down discs ask before they act.
      logOut = pkgs.writers.writeBash "log-out" ''
        hyprctl=${hyprctl}
        stamp="$XDG_RUNTIME_DIR/hyprland-log-out"
        now=$(date +%s)

        if [ -f "$stamp" ] && [ $((now - $(cat "$stamp"))) -le 3 ]; then
          rm -f "$stamp"
          exec $hyprctl dispatch 'hl.dsp.exit()'
        fi

        echo "$now" > "$stamp"
        ${notify} -a Hyprland -t 3000 \
          -h string:x-canonical-private-synchronous:log-out \
          "Log out?" "Press Super+Alt+Q again to quit all apps and log out."
      '';

      # helpers for the lua based hyprland configuration, see
      # https://wiki.hypr.land/Configuring/Start/
      lua = lib.generators.mkLuaInline;
      luaValue = lib.generators.toLua { };

      # dispatcher expression, e.g. `dsp "window.close()"` -> `hl.dsp.window.close()`
      dsp = expr: lua "hl.dsp.${expr}";
      # spawns `cmd` through a shell, with the command quoted as a lua string
      exec = cmd: lua "hl.dsp.exec_cmd(${luaValue cmd})";

      mkBindWith = opts: keys: dispatcher: {
        _args = [
          keys
          dispatcher
        ]
        ++ lib.optional (opts != { }) opts;
      };
      mkBind = mkBindWith { };
      # keeps working while the session is locked (former `bindl`)
      mkBindLocked = mkBindWith { locked = true; };
      # mouse bind (former `bindm`)
      mkBindMouse = mkBindWith { mouse = true; };
    in
    lib.mkIf config.custom.hyprland.enable {
      xdg.portal = {
        enable = true;
        extraPortals = [
          pkgs.xdg-desktop-portal-hyprland
          pkgs.xdg-desktop-portal-gtk # used to provide additional properties (e.g. appearance settings for dark-mode)
        ];
        config.common = {
          default = [
            "hyprland"
            "gtk"
          ];
        };
      };

      wayland.windowManager.hyprland = {
        enable = true;
        configType = "lua";

        # Import the whole environment into systemd/dbus instead of the
        # default handful of variables, otherwise apps started through the
        # user manager (portals, launchers) miss PATH/NIX/... and launch slowly
        # or with the wrong backend.
        systemd.variables = [ "--all" ];

        settings = {
          #########################
          # Environment           #
          #########################

          # Force all apps to use Wayland.
          env = [
            {
              _args = [
                "GDK_BACKEND"
                "wayland,x11,*"
              ];
            }
            {
              _args = [
                "QT_QPA_PLATFORM"
                "wayland;xcb"
              ];
            }
            {
              _args = [
                "MOZ_ENABLE_WAYLAND"
                "1"
              ];
            }
            {
              _args = [
                "ELECTRON_OZONE_PLATFORM_HINT"
                "wayland"
              ];
            }
          ];

          #########################
          # Hardware              #
          #########################

          monitor = [
            {
              output = monitors.left;
              mode = "preferred";
              position = "0x0";
              scale = "1";
            }
            {
              output = monitors.center;
              mode = "preferred";
              position = "2560x0";
              scale = "1";
            }
            {
              output = monitors.right;
              mode = "preferred";
              position = "6000x0";
              scale = "1";
            }
          ];

          workspace_rule = [
            # left
            {
              workspace = "1";
              monitor = monitors.left;
            }
            {
              workspace = "2";
              monitor = monitors.left;
            }

            # center
            {
              workspace = "3";
              monitor = monitors.center;
              default = true;
            }
            {
              workspace = "6";
              monitor = monitors.center;
            }
            {
              workspace = "7";
              monitor = monitors.center;
            }
            {
              workspace = "8";
              monitor = monitors.center;
            }
            {
              workspace = "9";
              monitor = monitors.center;
            }
            {
              workspace = "10";
              monitor = monitors.center;
            }

            # right
            {
              workspace = "4";
              monitor = monitors.right;
            }
            {
              workspace = "5";
              monitor = monitors.right;
            }
          ];

          config = {
            input = {
              kb_layout = "us";
              kb_variant = "altgr-intl";
              kb_options = "compose:rwin,caps:escape";

              numlock_by_default = true;

              repeat_rate = 40;
              repeat_delay = 250;

              follow_mouse = 1;

              touchpad = {
                natural_scroll = true;
                clickfinger_behavior = true;
                scroll_factor = 0.2;
              };

              sensitivity = 0.2;
            };

            cursor = {
              no_hardware_cursors = 0;
              default_monitor = monitors.center;
              hide_on_key_press = true;
            };

            #########################
            # General               #
            #########################

            general = {
              # 2 units either side, so neighbouring windows sit the shell's
              # `space2` apart, and `space3` from the edge of the screen
              gaps_in = px 4;
              gaps_out = px 12;

              border_size = 1;
              "col.active_border" = hairline.active;
              "col.inactive_border" = hairline.inactive;

              layout = "scrolling";

              # only windows matched by an `immediate` rule (games) tear
              allow_tearing = true;
            };

            # scan fullscreen game content out directly, skipping composition;
            # set to 0 if it ever flickers on nvidia
            render.direct_scanout = 2;

            decoration = {
              # the shell's medium radius, with the corner eased into the
              # sides rather than a quarter circle stuck onto them
              rounding = px 14;
              rounding_power = 3;

              shadow = {
                enabled = true;
                range = 40;
                render_power = 3;
                offset = "0 12";
                color = "rgba(0000008c)";
                color_inactive = "rgba(00000040)";
              };

              # Frosts what shows through a translucent terminal and the
              # shell's glass (see `layer_rule`): wide and a little more
              # saturated, so the desktop behind reads as colour and light
              # rather than as shapes competing with the text. With reduced
              # transparency nothing is see-through, so there is nothing to
              # frost.
              blur = {
                enabled = !a11y.reduceTransparency;
                size = 6;
                passes = 3;
                vibrancy = 0.2;
                popups = true;
                new_optimizations = true;
              };
            };

            animations.enabled = true;

            misc = {
              # only seen for the moment before hyprpaper draws
              background_color = "rgb(${colors.base00})";

              disable_hyprland_logo = true;
              disable_splash_rendering = true;
              disable_scale_notification = true;

              # let apps that request focus (e.g. a browser opening a link)
              # actually get it
              focus_on_activate = true;

              # give slow apps more time before the "not responding" dialog
              anr_missed_pings = 3;

              # wake the screens on any input, not just on mouse movement
              key_press_enables_dpms = true;
              mouse_move_enables_dpms = true;

              # let a fresh hyprlock re-acquire the session lock after the
              # previous lock client died instead of leaving a red screen
              allow_session_lock_restore = true;

              # keep drawing the workspaces below the lock surface, so hyprlock
              # fades into the desktop on unlock instead of into black
              session_lock_xray = true;
            };

            xwayland.force_zero_scaling = true;

            ecosystem = {
              no_update_news = true;
              no_donation_nag = true;
            };
          };

          #########################
          # Animations            #
          #########################

          # curves are emitted at the top of the config (see
          # `importantPrefixes`), so the animations below can reference them
          curve = lib.mapAttrsToList (name: curve: {
            _args = [
              name
              curve
            ];
          }) motion.curves;

          animation = map (
            {
              leaf,
              speed,
              curve,
              ...
            }@anim:
            {
              inherit leaf speed;
              enabled = true;
              # `default` is hyprland's own, and a bezier
              ${motion.curves.${curve}.type or "bezier"} = curve;
            }
            // removeAttrs anim [ "curve" ]
          ) motion.animations;

          #########################
          # Startup Programs      #
          #########################

          on = [
            {
              _args = [
                "hyprland.start"
                (lua "function() hl.exec_cmd(${luaValue "${lib.getExe pkgs._1password-gui} --silent"}) end")
              ];
            }
          ];

          #########################
          # Keyboard Shortcuts    #
          #########################

          bind = [
            (mkBind "${mod} + ALT + Q" (exec "${logOut}"))
            (mkBind "${mod} + SHIFT + Q" (dsp "window.close()"))
            (mkBind "${mod} + CONTROL + Q" (exec "${pkgs.systemd}/bin/loginctl lock-session"))

            # the notch and its launcher, see `custom.shell` below; run from
            # the profile so the ipc call reaches the very instance the user
            # service runs
            (mkBind "${mod} + SPACE" (
              exec "${config.home.profileDirectory}/bin/shell ipc call launcher toggle"
            ))
            (mkBind "${mod} + D" (exec "${config.home.profileDirectory}/bin/shell ipc call notch toggle"))

            # terminal
            (mkBind "${mod} + RETURN" (exec (lib.getExe pkgs.ghostty)))
            (mkBind "${mod} + SHIFT + RETURN" (
              exec "${lib.getExe pkgs.ghostty} --class=com.mitchellh.ghostty-floating"
            ))

            # workspace switching
            (mkBind "${mod} + 1" (dsp "focus({ workspace = 1 })"))
            (mkBind "${mod} + 2" (dsp "focus({ workspace = 2 })"))
            (mkBind "${mod} + 3" (dsp "focus({ workspace = 3 })"))
            (mkBind "${mod} + 4" (dsp "focus({ workspace = 4 })"))
            (mkBind "${mod} + 5" (dsp "focus({ workspace = 5 })"))
            (mkBind "${mod} + 6" (dsp "focus({ workspace = 6 })"))
            (mkBind "${mod} + 7" (dsp "focus({ workspace = 7 })"))
            (mkBind "${mod} + 8" (dsp "focus({ workspace = 8 })"))
            (mkBind "${mod} + 9" (dsp "focus({ workspace = 9 })"))
            (mkBind "${mod} + 0" (dsp "focus({ workspace = 10 })"))

            # move window to workspace
            (mkBind "${mod} + SHIFT + 1" (dsp "window.move({ workspace = 1 })"))
            (mkBind "${mod} + SHIFT + 2" (dsp "window.move({ workspace = 2 })"))
            (mkBind "${mod} + SHIFT + 3" (dsp "window.move({ workspace = 3 })"))
            (mkBind "${mod} + SHIFT + 4" (dsp "window.move({ workspace = 4 })"))
            (mkBind "${mod} + SHIFT + 5" (dsp "window.move({ workspace = 5 })"))
            (mkBind "${mod} + SHIFT + 6" (dsp "window.move({ workspace = 6 })"))
            (mkBind "${mod} + SHIFT + 7" (dsp "window.move({ workspace = 7 })"))
            (mkBind "${mod} + SHIFT + 8" (dsp "window.move({ workspace = 8 })"))
            (mkBind "${mod} + SHIFT + 9" (dsp "window.move({ workspace = 9 })"))
            (mkBind "${mod} + SHIFT + 0" (dsp "window.move({ workspace = 10 })"))

            # move window
            (mkBind "${mod} + SHIFT + H" (dsp ''window.move({ direction = "left" })''))
            (mkBind "${mod} + SHIFT + L" (dsp ''window.move({ direction = "right" })''))
            (mkBind "${mod} + SHIFT + K" (dsp ''window.move({ direction = "up" })''))
            (mkBind "${mod} + SHIFT + J" (dsp ''window.move({ direction = "down" })''))

            # focus window
            (mkBind "${mod} + H" (dsp ''focus({ direction = "left" })''))
            (mkBind "${mod} + L" (dsp ''focus({ direction = "right" })''))
            (mkBind "${mod} + K" (dsp ''focus({ direction = "up" })''))
            (mkBind "${mod} + J" (dsp ''focus({ direction = "down" })''))

            # cycle the focused column through `scrolling.explicit_column_widths`
            (mkBind "${mod} + R" (dsp ''layout("colresize +conf")''))
            (mkBind "${mod} + SHIFT + R" (dsp ''layout("colresize -conf")''))

            # toggle fullscreen, floating
            (mkBind "${mod} + M" (dsp ''window.fullscreen({ mode = "maximized" })''))

            # TODO (mkBind "${mod} + SPACE" (dsp "window.cycle_next({ floating = true })"))
            (mkBind "${mod} + SHIFT + SPACE" (dsp "window.float()"))

            # center window
            (mkBind "${mod} + SHIFT + C" (dsp "window.center()"))

            # scratchpad
            (mkBind "${mod} + SHIFT + MINUS" (dsp ''window.move({ workspace = "special" })''))
            (mkBind "${mod} + MINUS" (dsp "workspace.toggle_special()"))

            # screenshot
            (mkBind "${mod} + SHIFT + F4" (exec "${screenshot} area"))
            (mkBind "${mod} + SHIFT + F3" (exec "${screenshot} window"))
          ]
          ++
            # locked binds, these also fire while the session is locked
            (
              let
                focusSpotify = pkgs.writers.writeBash "focus-spotify" ''
                  ${lib.getExe pkgs.playerctl} -l | grep -v spotify | xargs -I {} ${lib.getExe pkgs.playerctl} -p {} pause
                  ${lib.getExe pkgs.playerctl} -p spotify volume 0.6
                '';
                unfocusSpotify = pkgs.writers.writeBash "unfocus-spotify" ''
                  ${lib.getExe pkgs.playerctl} -p spotify volume 0.3
                '';
              in
              [
                # volume control
                (mkBindLocked "XF86AudioRaiseVolume" (
                  exec "${pkgs.wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
                ))
                (mkBindLocked "XF86AudioLowerVolume" (
                  exec "${pkgs.wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
                ))
                (mkBindLocked "XF86AudioMute" (
                  exec "${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
                ))

                # spotify controls
                (mkBindLocked "XF86AudioPlay" (exec "${lib.getExe pkgs.playerctl} -p spotify play-pause"))
                (mkBindLocked "XF86AudioPause" (exec "${lib.getExe pkgs.playerctl} -a pause"))
                (mkBindLocked "XF86AudioStop" (exec "${lib.getExe pkgs.playerctl} -a pause"))
                (mkBindLocked "XF86AudioNext" (exec "${lib.getExe pkgs.playerctl} -p spotify next"))
                (mkBindLocked "XF86AudioPrev" (exec "${lib.getExe pkgs.playerctl} -p spotify previous"))

                (mkBindLocked "XF86Launch6" (exec "${focusSpotify}"))
                (mkBindLocked "XF86MonBrightnessUp" (exec "${focusSpotify}"))
                (mkBindLocked "XF86Launch5" (exec "${unfocusSpotify}"))
                (mkBindLocked "XF86MonBrightnessDown" (exec "${unfocusSpotify}"))
              ]
            )
          ++ [
            # mouse binds
            (mkBindMouse "${mod} + mouse:272" (dsp "window.drag()"))
            (mkBindMouse "${mod} + SHIFT + mouse:272" (dsp "window.resize()"))
          ];

          #########################
          # Window Rules          #
          #########################

          window_rule = [
            # ignore apps asking to maximize themselves; the layout decides
            {
              name = "suppress-maximize";
              match.class = ".*";
              suppress_event = "maximize";
            }

            # fix some dragging issues with XWayland
            {
              name = "xwayland-drag-fix";
              match = {
                class = "^$";
                title = "^$";
                xwayland = true;
                float = true;
                fullscreen = false;
                pin = false;
              };
              no_focus = true;
            }

            {
              name = "1password";
              match.class = "1Password";

              float = true;
              center = true;
              size = "1024 720";
            }

            {
              name = "spotify";
              # native Wayland (NIXOS_OZONE_WL) reports a lowercase app id
              match.class = "^([Ss]potify)$";

              workspace = "special";
            }

            # skip vsync for games (needs general.allow_tearing)
            {
              name = "games-immediate";
              match.class = "^(steam_app_.*|gamescope)$";
              immediate = true;
            }

            {
              name = "ghostty-floating";
              match.class = "com.mitchellh.ghostty-floating";

              float = true;
              center = true;
              size = "1024 720";
            }
          ];

          # The shell's glass — Spotlight, the toasts, the volume reading, the
          # password pane — is only frosted if the compositor frosts it; the
          # bezel is opaque, so the blur only ever shows under the glass.
          # `ignore_alpha` keeps it off the faint shadow around a pane. The
          # shell moves its own surfaces, so hyprland's layer fade is left
          # off them rather than played on top.
          layer_rule =
            map
              (surface: {
                name = "shell-${surface}";
                match.namespace = "^shell-${surface}$";

                blur = true;
                ignore_alpha = 0.5;
                no_anim = true;
              })
              [
                "notch"
                "spotlight"
                "polkit"
              ];
        };
      };

      home.pointerCursor = {
        enable = true;
        hyprcursor.enable = true;
      };

      services = {
        hypridle = {
          enable = true;
          settings = {
            general = {
              lock_cmd = "pidof hyprlock || ${lib.getExe pkgs.hyprlock}";
              before_sleep_cmd = "${pkgs.systemd}/bin/loginctl lock-session";
              after_sleep_cmd = "${pkgs.hyprland}/bin/hyprctl dispatch 'hl.dsp.dpms(\"on\")'";

              # hold the suspend until hyprlock has the session, so waking up
              # shows the lock screen rather than a frame of the desktop first
              inhibit_sleep = 3;

              # browsers can leave wayland idle inhibitors dangling after
              # playback stops; rely on their dbus wake locks instead
              ignore_wayland_inhibit = true;
            };

            listener = [
              {
                timeout = 300; # 5min
                on-timeout = "${pkgs.systemd}/bin/loginctl lock-session";
              }
              {
                timeout = 330; # 5.5min
                on-timeout = "${pkgs.hyprland}/bin/hyprctl dispatch 'hl.dsp.dpms(\"off\")'";
                on-resume = "${pkgs.hyprland}/bin/hyprctl dispatch 'hl.dsp.dpms(\"on\")'";
              }
              {
                timeout = 1800; # 30min
                on-timeout = "${pkgs.systemd}/bin/systemctl suspend";
              }
            ];
          };
        };

        hyprpaper = {
          enable = true;
          settings.splash = false;
        };
      };

      programs = {
        hyprlock = {
          enable = true;
          settings =
            let
              font = config.stylix.fonts.sansSerif.name;

              # everything hangs off one left edge in the dark lower-left corner
              # of the photo, like a caption, leaving the aurora and the peak
              # untouched
              caption = {
                monitor = monitors.center;
                halign = "left";
                valign = "bottom";
                font_family = font;
                color = "rgb(${colors.base05})";
              };
              x = 200;

              # lives in a script, hyprlang would parse playerctl's `{{ }}`
              # templates as arithmetic expressions
              nowPlaying = pkgs.writeShellScript "hyprlock-now-playing" ''
                ${lib.getExe pkgs.playerctl} metadata --format \
                  '{{markup_escape(title)}}  <span alpha="55%">{{markup_escape(artist)}}</span>' \
                  2>/dev/null
              '';
            in
            {
              general = {
                hide_cursor = true;
                ignore_empty_input = true;
              };

              # locking dissolves the windows into the bare landscape, unlocking
              # gets out of the way quickly since the session only unlocks once
              # the fade-out finished
              animations = {
                enabled = true;
                bezier = [
                  "ease, 0.25, 0.1, 0.25, 1"
                  "easeOut, 0.16, 1, 0.3, 1"
                ];
                animation = [
                  "fadeIn, 1, 8, ease"
                  "fadeOut, 1, 3, easeOut"
                  "inputFieldDots, 1, 1.5, easeOut"
                  "inputFieldWidth, 1, 3, easeOut"
                  "inputFieldColors, 1, 5, ease"
                  "inputFieldFade, 1, 3, ease"
                ];
              };

              # the plain wallpaper, the same one hyprpaper shows on the desktop
              background = {
                monitor = "";
                color = "rgb(${colors.base00})";
                path = toString (
                  # shrink to the widest monitor; decoding and uploading the
                  # full-size image on every lock makes the fade-in stutter
                  pkgs.runCommand "wallpaper-lock.png" { buildInputs = [ pkgs.ffmpeg ]; } ''
                    ffmpeg -y -i ${config.stylix.image} -vf "scale=3440:-2" $out
                  ''
                );
              };

              label = [
                # time in the display cut of inter, tabular figures keep the
                # digits from shifting every minute
                (
                  caption
                  // {
                    text = ''<span font_family="Inter Display" font_weight="200" font_features="tnum">$TIME</span>'';
                    font_size = 132;
                    position = "${toString (x - 8)}, 318";
                  }
                )

                (
                  caption
                  // {
                    text = "cmd[update:60000] date +'%A, %-d. %B'";
                    color = "rgba(${colors.base05}d9)";
                    font_size = 20;
                    position = "${toString x}, 282";
                  }
                )

                # empty without a player
                (
                  caption
                  // {
                    text = "cmd[update:2000] ${nowPlaying}";
                    color = "rgba(${colors.base05}b3)";
                    font_size = 12;
                    position = "${toString x}, 150";
                  }
                )
              ];

              input-field = {
                monitor = monitors.center;
                size = "340, 48";

                # a capsule, like everything you type into in the shell
                rounding = -1;
                outline_thickness = 1;
                outer_color = "rgba(${colors.base05}59)";
                inner_color = "rgba(${colors.base00}8c)";
                font_color = "rgb(${colors.base05})";
                font_family = font;

                # The outline takes on the aurora's green while checking. A
                # wrong password says so in words as well as in red; there is
                # no caps lock colour, caps lock is escape (`kb_options`).
                check_color = "rgb(${colors.base0B})";
                fail_color = "rgb(${colors.base08})";

                dots_size = 0.16;
                dots_spacing = 0.6;
                dots_center = true;
                dots_rounding = -1;

                # 60% of the ink is ~5.2:1 on the field over the water, the
                # 4.5:1 body text needs
                placeholder_text = ''<span alpha="60%">Password</span>'';
                # the shell's password pane says the same
                fail_text = "Incorrect password. Try again.";

                halign = "left";
                valign = "bottom";
                position = "${toString x}, 196";

                fade_on_empty = false;
                hide_input = false;
              };
            };
        };
      };

      # the bar and the application launcher, a custom quickshell
      # implementation living in https://github.com/thecodinglab/shell
      custom.shell = {
        enable = true;

        settings = {
          diskPath = "/";
          networkInterface = "enp13s0";
          # what the launcher runs console applications in
          terminal = lib.getExe pkgs.ghostty;

          # move on the compositor's curves, see `motion`
          inherit (motion) curves;
          animations = lib.listToAttrs (
            map (
              { leaf, ... }@anim:
              lib.nameValuePair leaf (lib.filterAttrs (name: _: name == "curve" || name == "speed") anim)
            ) motion.animations
          );

          reducedMotion = a11y.reduceMotion;
          reducedTransparency = a11y.reduceTransparency;
          increaseContrast = a11y.increaseContrast;
        };
      };

      stylix = {
        # window colours are the hairlines and shadows above, not the
        # palette's accent
        targets.hyprland.colors.enable = false;

        # hyprlock wallpaper and colors are managed above
        targets.hyprlock = {
          image.enable = false;
          colors.enable = false;
        };

        # a terminal is content, not something floating over it: with reduced
        # transparency it is solid like everything else
        opacity.terminal = lib.mkIf a11y.reduceTransparency (lib.mkForce 1.0);
      };

      home.packages = [
        pkgs.wl-clipboard

        # Screenshot Utilities
        pkgs.grim
        pkgs.slurp

        # Audio Control
        pkgs.pulseaudio
        pkgs.playerctl
      ];
    };
}
