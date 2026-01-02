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
            kb_options = "compose:rwin,caps:escape";

            numlock_by_default = true;

            follow_mouse = 1;

            touchpad = {
              natural_scroll = true;
              clickfinger_behavior = true;
              scroll_factor = 0.2;
            };

            sensitivity = 0.2;
          };

          #########################
          # General               #
          #########################

          general = {
            gaps_in = 10;
            gaps_out = "5,30,30,30";

            border_size = 2;

            layout = "master";
          };

          decoration.rounding = 10;

          animations.enabled = true;

          master.mfact = 0.7;

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

          ecosystem = {
            no_update_news = true;
            no_donation_nag = true;
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
            "${mod}, D, exec, ${lib.getExe pkgs.vicinae} toggle"

            # terminal
            "${mod}, RETURN, exec, ${lib.getExe pkgs.ghostty}"
            "${mod} SHIFT, RETURN, exec, ${lib.getExe pkgs.ghostty} --class=com.mitchellh.ghostty-floating"

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

            # screenshot
            "${mod} SHIFT, F4, exec, ${lib.getExe pkgs.grim} -g \"\$(${lib.getExe pkgs.slurp})\" -t png - | ${lib.getExe' pkgs.wl-clipboard "wl-copy"} -t image/png"
            "${mod} SHIFT, F3, exec, ${pkgs.writers.writeBash "screenshot-window" ''
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
          ];

          bindl =
            let
              focusSpotify = pkgs.writers.writeBash "focus-spotify" ''
                ${lib.getExe pkgs.playerctl} -l | grep -v spotify | xargs -I {} ${lib.getExe pkgs.playerctl} -p {} pause
                ${lib.getExe pkgs.playerctl} -p spotify volume 0.6
              '';
              unfocusSpotify = pkgs.writers.writeBash "unfocus-spotify" ''
                ${lib.getExe pkgs.playerctl} -p spotify volume 0.2
              '';
            in
            [
              # volume control
              ", XF86AudioRaiseVolume, exec, ${pkgs.wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
              ", XF86AudioLowerVolume, exec, ${pkgs.wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
              ", XF86AudioMute, exec, ${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"

              # spotify controls
              ", XF86AudioPlay,  exec, ${lib.getExe pkgs.playerctl} -p spotify play-pause"
              ", XF86AudioPause, exec, ${lib.getExe pkgs.playerctl} -a pause"
              ", XF86AudioStop,  exec, ${lib.getExe pkgs.playerctl} -a pause"
              ", XF86AudioNext,  exec, ${lib.getExe pkgs.playerctl} -p spotify next"
              ", XF86AudioPrev,  exec, ${lib.getExe pkgs.playerctl} -p spotify previous"

              ", XF86Launch6,           exec, ${focusSpotify}"
              ", XF86MonBrightnessUp,   exec, ${focusSpotify}"
              ", XF86Launch5,           exec, ${unfocusSpotify}"
              ", XF86MonBrightnessDown, exec, ${unfocusSpotify}"

            ];

          bindm = [
            "${mod}, mouse:272, movewindow"
            "${mod} SHIFT, mouse:272, resizewindow"
          ];

          #########################
          # Window Rules          #
          #########################

          windowrule = [
            # 1Password
            "match:class 1password, float on"
            "match:class 1password, center on"
            "match:class 1password, size 1024 720"

            # Spotify
            "match:class Spotify, workspace special"

            # Ghostty
            "match:class com.mitchellh.ghostty-floating, float on"
            "match:class com.mitchellh.ghostty-floating, center on"
            "match:class com.mitchellh.ghostty-floating, size 1024 720"
          ];
        };
      };

      services = {
        hypridle = {
          enable = true;
          settings = {
            general = {
              lock_cmd = "pidof hyprlock || ${lib.getExe pkgs.hyprlock}";
              before_sleep_cmd = "${pkgs.systemd}/bin/loginctl lock-session";
              after_sleep_cmd = "${pkgs.hyprland}/bin/hyprctl dispatch dpms on";
            };

            listener = [
              {
                timeout = 300; # 5min
                on-timeout = "${pkgs.systemd}/bin/loginctl lock-session";
              }
              {
                timeout = 330; # 5.5min
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
      };

      programs.vicinae = {
        enable = true;
        systemd.enable = true;
        settings = {
          font.size = 10;
          theme.name = "vicinae-dark";
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
      ];
    };
}
