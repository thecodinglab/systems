{
  config,
  pkgs,
  lib,
  ...
}:
{
  options.custom.hyprland = {
    enable = lib.mkEnableOption "enable hyprland";
  };

  config =
    let
      mod = "SUPER";
      monitors = {
        left = "DP-7";
        center = "DP-4";
        right = "DP-6";
      };

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
            {
              _args = [
                "OZONE_PLATFORM"
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
              gaps_in = 8;
              gaps_out = {
                top = 4;
                right = 8;
                bottom = 8;
                left = 8;
              };

              border_size = 2;

              layout = "master";
            };

            decoration = {
              rounding = 10;

              blur = {
                enabled = true;
                size = 8;
                passes = 3;
                new_optimizations = true;
              };
            };

            animations.enabled = false;

            master.mfact = 0.7;

            misc = {
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
            };

            xwayland.force_zero_scaling = true;

            ecosystem = {
              no_update_news = true;
              no_donation_nag = true;
            };
          };

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
            (mkBind "${mod} + ALT + Q" (dsp "exit()"))
            (mkBind "${mod} + SHIFT + Q" (dsp "window.close()"))
            (mkBind "${mod} + CONTROL + Q" (exec "${pkgs.systemd}/bin/loginctl lock-session"))

            # application launcher
            (mkBind "${mod} + D" (exec "${lib.getExe pkgs.vicinae} toggle"))

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

            # toggle fullscreen, floating
            (mkBind "${mod} + M" (dsp ''window.fullscreen({ mode = "maximized" })''))

            (mkBind "${mod} + SPACE" (dsp "window.cycle_next({ floating = true })"))
            (mkBind "${mod} + SHIFT + SPACE" (dsp "window.float()"))

            # center window
            (mkBind "${mod} + SHIFT + C" (dsp "window.center()"))

            # scratchpad
            (mkBind "${mod} + SHIFT + MINUS" (dsp ''window.move({ workspace = "special" })''))
            (mkBind "${mod} + MINUS" (dsp "workspace.toggle_special()"))

            # screenshot
            (mkBind "${mod} + SHIFT + F4" (
              exec ''${lib.getExe pkgs.grim} -g "$(${lib.getExe pkgs.slurp})" -t png - | ${lib.getExe' pkgs.wl-clipboard "wl-copy"} -t image/png''
            ))
            (mkBind "${mod} + SHIFT + F3" (
              exec "${pkgs.writers.writeBash "screenshot-window" ''
                set -e

                hyprctl=${lib.getExe' pkgs.hyprland "hyprctl"}
                jq=${lib.getExe pkgs.jq}
                slurp=${lib.getExe pkgs.slurp}
                grim=${lib.getExe pkgs.grim}
                copy=${lib.getExe' pkgs.wl-clipboard "wl-copy"}

                # select area
                area=$($hyprctl clients -j | $jq --argjson active $($hyprctl monitors -j | $jq -c '[.[].activeWorkspace.id]') '.[] | select((.hidden | not) and (.workspace.id as $id | $active | contains([$id]))) | "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"' -r | $slurp)
                # make screenshot
                $grim -g "$area" -t png - | $copy -t image/png
              ''}"
            ))
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
              match.class = "Spotify";

              workspace = "special";
            }

            {
              name = "ghostty-floating";
              match.class = "com.mitchellh.ghostty-floating";

              float = true;
              center = true;
              size = "1024 720";
            }
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
            ];
          };
        };

        hyprpaper = {
          enable = true;
          settings.splash = false;
        };

        dunst = {
          enable = true;

          settings = {
            global = {
              ### Display ###

              monitor = "0";
              follow = "mouse";

              ### Geometry ###

              origin = "top-right";
              offset = "8x0";
              width = 320;

              padding = "8";
              horizontal_padding = "10";
              text_icon_padding = "0";
              corner_radius = "16";
              gap_size = "5";

              ### Color ###

              frame_width = "2";
              separator_height = "1";

              sort = "yes";
              idle_threshold = "120";

              ### Text ###

              line_height = "0";

              format = "<b>%a</b> %s %p\n%b";
              markup = "full";

              alignment = "left";
              vertical_alignment = "center";

              show_age_threshold = "60";
              ellipsize = "middle";

              ignore_newline = "no";

              stack_duplicates = "true";
              hide_duplicate_count = "false";
              show_indicators = "yes";

              ### Icons ###

              icon_position = "left";
              min_icon_size = "0";
              max_icon_size = "64";
              icon_corner_radius = "16";

              ### History ###

              sticky_history = "yes";
              history_length = "20";

              ### Misc/Advanced ###

              always_run_script = "true";
              ignore_dbusclose = "false";

              ### Mouse ###

              mouse_left_click = "close_current";
              mouse_middle_click = "do_action, close_current";
              mouse_right_click = "close_all";
            };

            experimental.per_monitor_dpi = "false";

            urgency_low.timeout = "10";
            urgency_normal.timeout = "10";
            urgency_critical.timeout = "0";
          };
        };
      };

      programs = {
        waybar = {
          enable = true;
          systemd.enable = true;

          style = ''
            * {
              border: none;
              border-radius: 8px;
            }

            window#waybar {
              background: transparent;
            }

            .modules-left, .modules-center, .modules-right {
              margin: 8px;

              background: @base00;
              color: @base05;
            }

            .modules-center, .modules-right {
              padding: 0 8px;
            }

            .modules-left #workspaces button {
              padding: 1px 8px;
              background: transparent;
              border-bottom: none;
            }

            .modules-left #workspaces button.focused,
            .modules-left #workspaces button.active {
              background: shade(@base0D, 0.5);
              border-bottom: none;
            }

            #workspaces button.urgent {
              background: shade(@base08, 0.5);
              border-bottom: none;
            }

            #clock, #disk, #pulseaudio, #cpu, #memory, #network {
              padding: 0 2px;
            }
          '';

          settings = {
            mainBar = {
              layer = "top";
              position = "top";
              spacing = 20;

              modules-left = [ "hyprland/workspaces" ];
              modules-center = [ "clock" ];
              modules-right = [
                "disk#root"
                "pulseaudio"
                "cpu"
                "memory"
                "network#ethernet"
              ];

              "hyprland/workspaces" = {
                sort-by-number = true;
              };

              "disk#root" = {
                format = "/  {free}";
                path = "/";
              };

              "disk#data" = {
                format = "/media/data  {free}";
                path = "/media/data";
              };

              pulseaudio = {
                format = "󰕾   {volume}%";
                format-muted = "󰝟 ";
              };

              cpu = {
                format = "   {usage}%";
              };

              memory = {
                format = "   {avail} GiB";
              };

              "network#ethernet" = {
                interface = "enp13s0";
                format-ethernet = "󰛳   {ipaddr}";
                format-linked = "󰅛   (no ip)";
                format-disconnected = "󰅛 ";
              };

              "network#wifi" = {
                interface = "wlp15s0";
                format-wifi = "{icon}   {ipaddr}";
                format-linked = "󰤭   (no ip)";
                format-disconnected = "󰤭 ";
                format-icons = [
                  "󰤯"
                  "󰤟"
                  "󰤢"
                  "󰤥"
                  "󰤨"
                ];
              };

              clock = {
                format = "{:%H:%M  –  %d. %B %Y}";
                interval = 15;
              };
            };
          };
        };

        hyprlock = {
          enable = true;
          settings = {
            background = {
              monitor = "";
              path = builtins.toString (
                pkgs.runCommand "wallpaper-blurred.png" { buildInputs = [ pkgs.ffmpeg ]; } ''
                  ffmpeg -y -i ${config.stylix.image} -vf "gblur=sigma=30:steps=3" $out
                ''
              );
            };

            label = {
              monitor = monitors.center;
              text = ''cmd[update:1000] echo "$(date +"%H:%M")"'';

              color = "rgb(200, 200, 200)";
              font_family = config.stylix.fonts.sansSerif.name;
              font_size = 100;

              halign = "center";
              valign = "top";
              position = "0, -200";
            };

            input-field = {
              monitor = monitors.center;
              size = "200, 50";

              dots_size = 0.2;
              dots_spacing = 0.2;
              dots_center = true;

              outline_thickness = 2;

              halign = "center";
              valign = "bottom";
              position = "0, 100";

              fade_on_empty = true;
              hide_input = false;
            };
          };
        };

        vicinae = {
          enable = true;
          systemd.enable = true;
          settings = {
            font.normal.size = 12;
            theme.name = "vicinae-dark";

            close_on_focus_loss = true;
            launcher_window.compact_mode.enabled = true;

            favorites = [ ];
          };
        };
      };

      # hyprlock wallpaper is burred and managed above
      stylix.targets.hyprlock.image.enable = false;

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
