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
        left = "DP-4";
        center = "DP-5";
        right = "DP-7";
      };
    in
    lib.mkIf config.custom.hyprland.enable {
      home.sessionVariables = {
        GDK_BACKEND = "wayland";
      };

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

        settings = {
          env = [
            "XCURSOR_SIZE,24"
            "XDG_SESSION_TYPE,wayland"
            "WLR_NO_HARDWARE_CURSORS,1"

            "GBM_BACKEND,nvidia-drm"
            "__GLX_VENDOR_LIBRARY_NAME,nvidia"
          ];

          #########################
          # Hardware              #
          #########################

          monitor = [
            # left
            "${monitors.left}, preferred, 0x0, 1"
            # center
            "${monitors.center}, preferred, 2560x0, 1"
            # right
            "${monitors.right}, preferred, 6000x0, 1"
          ];

          workspace = [
            # left
            "1, monitor:${monitors.left}"
            "2, monitor:${monitors.left}"

            # center
            "3, monitor:${monitors.center}, default:true"
            "6, monitor:${monitors.center}"
            "7, monitor:${monitors.center}"
            "8, monitor:${monitors.center}"
            "9, monitor:${monitors.center}"
            "10, monitor:${monitors.center}"

            # right
            "4, monitor:${monitors.right}"
            "5, monitor:${monitors.right}"
          ];

          input = {
            kb_layout = "us";
            kb_variant = "altgr-intl";
            kb_options = "compose:rwin";

            numlock_by_default = true;

            follow_mouse = 1;

            touchpad = {
              natural_scroll = true;
              clickfinger_behavior = true;
              scroll_factor = 0.2;
            };

            sensitivity = 0.2;
          };

          gestures = {
            workspace_swipe = false;
          };

          #########################
          # General               #
          #########################

          general = {
            gaps_in = 10;
            gaps_out = "5,30,30,30";

            border_size = 2;

            layout = "dwindle";
          };

          decoration = {
            rounding = 10;

            blur = {
              enabled = false;
              size = 5;
              passes = 2;
            };
          };

          animations = {
            enabled = true;

            bezier = "ease, 0.5, 0.0, 0.5, 1.0";

            animation = [
              "windows, 1, 5, ease"
              "windowsOut, 1, 5, ease, popin 80%"
              "fade, 1, 5, default"
              "workspaces, 1, 5, ease"
            ];
          };

          dwindle = {
            pseudotile = true;
            preserve_split = true;

            force_split = 2; # always split to the right

            default_split_ratio = 1.2;
          };

          misc = {
            disable_hyprland_logo = true;
            disable_splash_rendering = true;
          };

          #########################
          # Startup Programs      #
          #########################

          exec-once = [ "${lib.getExe pkgs._1password-gui} --silent" ];

          #########################
          # Keyboard Shortcuts    #
          #########################

          bind = [
            "${mod} ALT, Q, exit,"
            "${mod} SHIFT, Q, killactive,"
            "${mod} CONTROL, Q , exec, ${pkgs.systemd}/bin/loginctl lock-session"

            # application launcher
            "${mod}, D, exec, ${pkgs.tofi}/bin/tofi-drun | xargs hyprctl dispatch exec --"
            "${mod} SHIFT, D, exec, ${pkgs.tofi}/bin/tofi-run | xargs hyprctl dispatch exec --"

            # terminal
            "${mod}, RETURN, exec, ${lib.getExe pkgs.ghostty}"

            # workspace switching
            "${mod}, 1, workspace, 1"
            "${mod}, 2, workspace, 2"
            "${mod}, 3, workspace, 3"
            "${mod}, 4, workspace, 4"
            "${mod}, 5, workspace, 5"
            "${mod}, 6, workspace, 6"
            "${mod}, 7, workspace, 7"
            "${mod}, 8, workspace, 8"
            "${mod}, 9, workspace, 9"
            "${mod}, 0, workspace, 10"

            # move window to workspace
            "${mod} SHIFT, 1, movetoworkspace, 1"
            "${mod} SHIFT, 2, movetoworkspace, 2"
            "${mod} SHIFT, 3, movetoworkspace, 3"
            "${mod} SHIFT, 4, movetoworkspace, 4"
            "${mod} SHIFT, 5, movetoworkspace, 5"
            "${mod} SHIFT, 6, movetoworkspace, 6"
            "${mod} SHIFT, 7, movetoworkspace, 7"
            "${mod} SHIFT, 8, movetoworkspace, 8"
            "${mod} SHIFT, 9, movetoworkspace, 9"
            "${mod} SHIFT, 0, movetoworkspace, 10"

            # move window
            "${mod} SHIFT, H, movewindow, l"
            "${mod} SHIFT, L, movewindow, r"
            "${mod} SHIFT, K, movewindow, u"
            "${mod} SHIFT, J, movewindow, d"

            # focus window
            "${mod}, H, movefocus, l"
            "${mod}, L, movefocus, r"
            "${mod}, K, movefocus, u"
            "${mod}, J, movefocus, d"

            # toggle fullscreen (monocle), split, floating
            "${mod}, M, fullscreen, 1"
            "${mod}, S, togglesplit,"

            "${mod}, SPACE, cyclenext, floating"
            "${mod} SHIFT, SPACE, togglefloating,"

            # center window
            "${mod} SHIFT, C, centerwindow,"

            # scratchpad
            "${mod} SHIFT, MINUS, movetoworkspace, special"
            "${mod}, MINUS, togglespecialworkspace,"

            # volume control
            ", XF86AudioRaiseVolume, exec, ${pkgs.pulseaudio}/bin/pactl set-sink-volume @DEFAULT_SINK@ +5%"
            ", XF86AudioLowerVolume, exec, ${pkgs.pulseaudio}/bin/pactl set-sink-volume @DEFAULT_SINK@ -5%"
            ", XF86AudioMute, exec, ${pkgs.pulseaudio}/bin/pactl set-sink-mute @DEFAULT_SINK@ toggle"
            ", XF86AudioMicMute, exec, ${pkgs.pulseaudio}/bin/pactl set-source-mute @DEFAULT_SOURCE@ toggle"

            # player control
            ", XF86AudioPlay, exec, ${lib.getExe pkgs.playerctl} play-pause"
            ", XF86AudioPause, exec, ${lib.getExe pkgs.playerctl} pause-pause"
            ", XF86AudioNext, exec, ${lib.getExe pkgs.playerctl} next"
            ", XF86AudioPrev, exec, ${lib.getExe pkgs.playerctl} previous"

          ];

          bindm = [
            "${mod}, mouse:272, movewindow"
            "${mod} SHIFT, mouse:272, resizewindow"
          ];

          #########################
          # Window Rules          #
          #########################

          windowrulev2 = [
            # 1Password
            "float, class:^1Password$"
            "center, class:^1Password$"

            # Spotify
            "workspace special, class:^Spotify$"
          ];

          layerrule = [
            "noanim, notifications"
          ];
        };
      };

      services = {
        hypridle = {
          enable = true;
          settings = {
            general = {
              lock_cmd = lib.getExe pkgs.hyprlock;
              after_sleep_cmd = "${pkgs.hyprland}/bin/hyprctl dispatch dpms on";
            };

            listener = [
              {
                timeout = 900;
                on-timeout = lib.getExe pkgs.hyprlock;
              }
              {
                timeout = 1200;
                on-timeout = "${pkgs.hyprland}/bin/hyprctl dispatch dpms off";
                on-resume = "${pkgs.hyprland}/bin/hyprctl dispatch dpms on";
              }
            ];

          };
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
              offset = "30x0";
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
              border-radius: 5px;
            }

            window#waybar {
              background: transparent;
            }

            .modules-left, .modules-center, .modules-right {
              margin: 10px 30px;

              background: @base00;
              color: @base05;
            }

            .modules-center, .modules-right {
              padding: 0 10px;
            }

            .modules-left #workspaces button {
              padding: 1px 10px;
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
                "disk#data"
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
                interface = "enp14s0";
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

        tofi = {
          enable = true;
          settings = {
            anchor = "top";
            width = "100%";
            height = 24;

            horizontal = true;
            prompt-text = " run: ";
            min-input-width = 120;
            result-spacing = 15;

            outline-width = 0;
            border-width = 0;
            padding-top = 4;
            padding-bottom = 4;
            padding-left = 0;
            padding-right = 0;
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
              font_family = "Inter";
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
      };

      # hyprlock wallpaper is burred and managed above
      stylix.targets.hyprlock.useWallpaper = false;

      home.packages = [
        pkgs.wl-clipboard

        # Screenshot Utilities
        pkgs.grim
        pkgs.slurp

        # Audio Control
        pkgs.pulseaudio
        pkgs.playerctl

        # Font
        pkgs.apple-font-sf-pro
      ];
    };
}
