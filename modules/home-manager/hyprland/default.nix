{ pkgs, lib, hyprland, hyprpaper, ... }:
let
  theme = import ../../../themes/nord;

  mkHyprColor = color:
    "rgb(" + lib.strings.removePrefix "#" color + ")";
in
lib.mkIf pkgs.stdenv.isLinux {
  wayland.windowManager.hyprland = {
    enable = true;
    package = hyprland.packages.${pkgs.system}.hyprland;

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
        "DP-7, preferred, 0x0, auto"
        "DP-6, preferred, 6000x0, auto"
        "DP-5, preferred, 2560x0, auto"
      ];

      workspace = [
        # left
        "1, monitor:DP-7"
        "2, monitor:DP-7"

        # center
        "3, monitor:DP-5, default:true"
        "6, monitor:DP-5"
        "7, monitor:DP-5"
        "8, monitor:DP-5"
        "9, monitor:DP-5"
        "10, monitor:DP-5"

        # right
        "4, monitor:DP-6"
        "5, monitor:DP-6"
      ];

      input = {
        kb_layout = "us";
        kb_variant = "altgr-intl";
        kb_options = "compose:ralt";

        numlock_by_default = true;

        follow_mouse = 1;

        touchpad = {
          natural_scroll = true;
          clickfinger_behavior = true;
        };

        sensitivity = 0.5;
      };

      gestures = {
        workspace_swipe = false;
      };

      #########################
      # General               #
      #########################

      general = {
        gaps_in = 5;
        gaps_out = 20;

        border_size = 2;
        "col.active_border" = mkHyprColor theme.nord10;
        "col.inactive_border" = mkHyprColor theme.nord0;

        layout = "dwindle";
      };

      decoration = {
        rounding = 0;

        blur.enabled = false;
        drop_shadow = false;
      };

      animations = {
        enabled = true;

        bezier = "myBezier, 0.05, 0.9, 0.1, 1.05";

        animation = [
          "windows, 1, 5, default"
          "windowsOut, 1, 5, default, popin 80%"
          "border, 1, 10, default"
          "borderangle, 1, 8, default"
          "fade, 1, 7, default"
          "workspaces, 1, 6, default"
        ];
      };

      dwindle = {
        pseudotile = true;
        preserve_split = true;

        force_split = 2; # always split to the right

        default_split_ratio = 1.2;
      };

      #########################
      # Keyboard Shortcuts    #
      #########################

      bind =
        let
          mod = "SUPER";
        in
        [
          # exit hyperland
          "${mod} ALT, Q, exit,"

          # window actions
          "${mod} SHIFT, Q, killactive,"

          # application launcher (TODO: theme)
          "${mod}, D, exec, ${pkgs.bemenu}/bin/bemenu-run --fn 'JetBrainsMono Nerd Font 14px' --line-height 20"

          # terminal
          "${mod}, RETURN, exec, ${lib.getExe pkgs.kitty}"

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

          # move workspace to monitor
          # "${mod} CONTROL SHIFT, 1, movecurrentworkspacetomonitor, DP-1"
          # "${mod} CONTROL SHIFT, 2, movecurrentworkspacetomonitor, DP-3"
          # "${mod} CONTROL SHIFT, 3, movecurrentworkspacetomonitor, DP-2"

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

          # resize window
          # binde = , L, resizeactive,10 0
          # binde = , H, resizeactive,-10 0
          # binde = , K, resizeactive,0 -10
          # binde = , J, resizeactive,0 10
          # "${mod}, R, submap, resize"

          # submap = resize
          # ", ESCAPE, submap, reset"
          # ", RETURN, submap, reset"
          # "${mod}, R, submap, reset"
          # submap = reset

          # # move/resize windows with mod + LMB/RMB and dragging
          # bindm = $mod, mouse:272, movewindow
          # bindm = $mod, mouse:273, resizewindow

          # toggle fullscreen (monocle), split, floating
          "${mod}, M, fullscreen, 1"
          "${mod}, S, togglesplit,"
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
    };
  };

  programs.waybar = {
    enable = true;
    systemd.enable = true;
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        spacing = 20;

        modules-left = [ "hyprland/workspaces" ];
        modules-right = [ "disk#root" "disk#data" "pulseaudio" "cpu" "memory" "network#ethernet" "network#wifi" "clock" ];

        "hyprland/workspaces" = {
          sort-by-number = true;
        };

        "disk#root" = {
          format = "/ {free}";
          path = "/";
        };

        "disk#data" = {
          format = "/media/data {free}";
          path = "/media/data";
        };

        pulseaudio = {
          format = "󰕾  {volume}%";
          format-muted = "󰝟 ";
        };

        cpu = {
          format = "  {usage}%";
        };

        memory = {
          format = "  {avail}GiB";
        };

        "network#ethernet" = {
          interface = "enp14s0";
          format-ethernet = "󰛳  {ipaddr}";
          format-linked = "󰅛  (no ip)";
          format-disconnected = "󰅛 ";

          tooltip-format = "{ifname} via {gwaddr}";
        };

        "network#wifi" = {
          interface = "wlp15s0";
          format-wifi = "{icon}  {ipaddr}";
          format-linked = "󰤭  (no ip)";
          format-disconnected = "󰤭 ";
          format-icons = [ "󰤯" "󰤟" "󰤢" "󰤥" "󰤨" ];

          tooltip-format = "{ifname} via {gwaddr}";
        };

        clock = {
          format = "{:%d.%m.%Y %H:%M}";
          interval = 15;
        };
      };
    };

    style = ''
      * {
        font-family: JetBrainsMono Nerd Font;
        font-size: 10pt;

        border: none;
        border-radius: 0;

        color: ${theme.nord4};
      }

      window#waybar {
        background: ${theme.nord0};
        color: ${theme.nord4};
      }

      button:hover {
        background: ${theme.nord2};
        box-shadow: none;
      }

      #workspaces {
        background: ${theme.nord0};
        color: ${theme.nord4};
      }

      #workspaces button.active {
        background: ${theme.nord10};
      }

      #workspaces button.urgent {
        background: ${theme.nord11};
      }

      button {
        padding: 0 5px;
      }
    '';
  };

  home.packages = [
    # Desktop Applications
    pkgs.bemenu
    pkgs.hyprpaper
  ];
}