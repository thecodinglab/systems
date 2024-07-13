{ pkgs, root, ... }:
let
  screenshotLocation = "/home/florian/Pictures/Screenshots";
in
{
  xsession.windowManager.i3 = {
    enable = true;
    config = rec {
      modifier = "Mod4";
      gaps.inner = 8;
      window.titlebar = false;

      workspaceOutputAssign = [
        { workspace = "1"; output = "DP-2"; }
        { workspace = "2"; output = "DP-0.8"; }
        { workspace = "3"; output = "DP-4"; }
      ];

      fonts = {
        names = [ "SauceCodePro Nerd Font" ];
        size = 8.0;
      };

      floating.criteria = [
        { instance = "1password"; }
        { instance = "spotify"; }
      ];

      window.commands = [
        { command = "move scratchpad"; criteria = { instance = "spotify"; }; }
      ];

      keybindings = {
        # Navigation
        "${modifier}+h" = "focus left";
        "${modifier}+j" = "focus down";
        "${modifier}+k" = "focus up";
        "${modifier}+l" = "focus right";
        "${modifier}+a" = "focus parent";

        "${modifier}+Shift+h" = "move left";
        "${modifier}+Shift+j" = "move down";
        "${modifier}+Shift+k" = "move up";
        "${modifier}+Shift+l" = "move right";

        # Workspace
        "${modifier}+1" = "workspace number 1";
        "${modifier}+2" = "workspace number 2";
        "${modifier}+3" = "workspace number 3";
        "${modifier}+4" = "workspace number 4";
        "${modifier}+5" = "workspace number 5";
        "${modifier}+6" = "workspace number 6";
        "${modifier}+7" = "workspace number 7";
        "${modifier}+8" = "workspace number 8";
        "${modifier}+9" = "workspace number 9";

        "${modifier}+Shift+1" = "move container to workspace number 1";
        "${modifier}+Shift+2" = "move container to workspace number 2";
        "${modifier}+Shift+3" = "move container to workspace number 3";
        "${modifier}+Shift+4" = "move container to workspace number 4";
        "${modifier}+Shift+5" = "move container to workspace number 5";
        "${modifier}+Shift+6" = "move container to workspace number 6";
        "${modifier}+Shift+7" = "move container to workspace number 7";
        "${modifier}+Shift+8" = "move container to workspace number 8";
        "${modifier}+Shift+9" = "move container to workspace number 9";

        # Layout
        "${modifier}+Shift+v" = "split h";
        "${modifier}+v" = "split v";
        "${modifier}+s" = "layout stacking";
        "${modifier}+w" = "layout tabbed";
        "${modifier}+e" = "layout toggle split";

        "${modifier}+f" = "fullscreen toggle";

        # Scratchpad
        "${modifier}+minus" = "scratchpad show";
        "${modifier}+Shift+minus" = "move scratchpad";

        # Floating
        "${modifier}+space" = "focus mode_toggle";
        "${modifier}+Shift+space" = "floating toggle";

        # Audio
        "XF86AudioRaiseVolume" = "exec --no-startup-id ${pkgs.pulseaudio}/bin/pactl set-sink-volume @DEFAULT_SINK@ +5%";
        "XF86AudioLowerVolume" = "exec --no-startup-id ${pkgs.pulseaudio}/bin/pactl set-sink-volume @DEFAULT_SINK@ -5%";
        "XF86AudioMute" = "exec --no-startup-id ${pkgs.pulseaudio}/bin/pactl set-sink-mute @DEFAULT_SINK@ toggle";
        "XF86AudioMicMute" = "exec --no-startup-id ${pkgs.pulseaudio}/bin/pactl set-source-mute @DEFAULT_SOURCE@ toggle";
        "XF86AudioPlay" = "exec --no-startup-id ${pkgs.playerctl}/bin/playerctl play-pause";
        "XF86AudioNext" = "exec --no-startup-id ${pkgs.playerctl}/bin/playerctl next";
        "XF86AudioPrev" = "exec --no-startup-id ${pkgs.playerctl}/bin/playerctl previous";

        # Screenshot
        "${modifier}+Shift+F3" = ''exec --no-startup-id "mkdir -p ${screenshotLocation};            ${pkgs.scrot}/bin/scrot -F '${screenshotLocation}/%Y-%m-%d_%H:%M:%s.jpg'   "'';
        "${modifier}+Shift+F4" = ''exec --no-startup-id "mkdir -p ${screenshotLocation}; sleep 0.2; ${pkgs.scrot}/bin/scrot -F '${screenshotLocation}/%Y-%m-%d_%H:%M:%s.jpg' -s"'';
        "${modifier}+Control+Shift+F3" = ''exec --no-startup-id "mkdir -p ${screenshotLocation};            ${pkgs.scrot}/bin/scrot -F '/tmp/scrot_%Y-%m-%d_%H:%M:%s.jpg' -o -e '${pkgs.xclip}/bin/xclip -selection clipboard -t image/png -i $f'   "'';
        "${modifier}+Control+Shift+F4" = ''exec --no-startup-id "mkdir -p ${screenshotLocation}; sleep 0.2; ${pkgs.scrot}/bin/scrot -F '/tmp/scrot_%Y-%m-%d_%H:%M:%s.jpg' -o -e '${pkgs.xclip}/bin/xclip -selection clipboard -t image/png -i $f' -s"'';

        # Other
        "${modifier}+d" = "exec ${pkgs.dmenu}/bin/dmenu_run";
        "${modifier}+Return" = "exec ${pkgs.alacritty}/bin/alacritty";
        "${modifier}+Control+q" = "exec ${pkgs.systemd}/bin/loginctl lock-session";

        "${modifier}+r" = "mode resize";
        "${modifier}+Shift+q" = "kill";
        "${modifier}+Shift+c" = "reload";
        "${modifier}+Shift+r" = "restart";
      };

      keycodebindings = {
        "248" = "exec ${pkgs.systemd}/bin/systemctl suspend";
      };

      modes = {
        resize =
          let
            amount = "10";
          in
          {
            h = "resize shrink width ${amount} px or ${amount} ppt";
            j = "resize grow height ${amount} px or ${amount} ppt";
            k = "resize shrink height ${amount} px or ${amount} ppt";
            l = "resize grow width ${amount} px or ${amount} ppt";

            Escape = "mode default";
            Return = "mode default";
            "${modifier}+r" = "mode default";
          };
      };

      startup = [
        { command = "${pkgs.xss-lock}/bin/xss-lock --transfer-sleep-lock -- ${pkgs.xsecurelock}/bin/xsecurelock"; always = true; notification = false; }
      ];
    };
  };

  programs.i3status = {
    enable = true;
    enableDefault = false;

    general = {
      colors = true;
      # color_good = "#e0e0e0";
      # color_degraded = "#d7ae00";
      # color_bad = "#f69d6a";
      interval = 5;
    };

    modules = {
      "wireless wlp15s0" = {
        position = 1;
        settings = {
          format_up = "W: %ip (%quality at %essid)";
          format_down = "W: down";
        };
      };

      "ethernet _first_" = {
        position = 2;
        settings = {
          format_up = "E: %ip (%speed)";
          format_down = "E: down";
        };
      };

      "volume master" = {
        position = 3;
        settings = {
          format = "%volume";
        };
      };

      "disk /" = {
        position = 4;
        settings = {
          format = "%avail";
        };
      };

      load = {
        position = 5;
        settings = {
          format = "%1min";
        };
      };

      memory = {
        position = 6;
        settings = {
          format = "%available";
          threshold_degraded = "1G";
          format_degraded = "MEMORY < %available";
        };
      };

      "tztime local" = {
        position = 7;
        settings = {
          format = "%Y-%m-%d %H:%M:%S";
        };
      };
    };
  };

  services.dunst = {
    enable = true;

    settings = {
      global = {
        ### Display ###

        monitor = "0";
        follow = "mouse";

        ### Geometry ###

        origin = "top-center";
        offset = "0x50";
        height = "300";

        padding = "8";
        horizontal_padding = "10";
        text_icon_padding = "0";

        ### Color ###

        # transparency = "15";

        separator_height = "1";
        separator_color = "frame";

        frame_width = "0";
        frame_color = "#282a36";

        sort = "yes";
        idle_threshold = "120";

        ### Text ###

        font = "Monospace 10";
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

        ### History ###

        sticky_history = "yes";
        history_length = "20";

        ### Misc/Advanced ###

        dmenu = "/usr/bin/dmenu -p dunst:";
        browser = "/usr/bin/firefox -new-tab";

        always_run_script = "true";

        title = "Dunst";
        class = "Dunst";

        corner_radius = "0";

        ignore_dbusclose = "false";

        ### Mouse ###

        mouse_left_click = "close_current";
        mouse_middle_click = "do_action, close_current";
        mouse_right_click = "close_all";
      };

      experimental.per_monitor_dpi = "false";

      urgency_low = {
        background = "#282a36";
        foreground = "#6272a4";
        timeout = "10";
      };

      urgency_normal = {
        background = "#282a36";
        foreground = "#bd93f9";
        timeout = "10";
      };

      urgency_critical = {
        background = "#ff5555";
        foreground = "#f8f8f2";
        frame_color = "#ff5555";
        timeout = "0";
      };
    };
  };

  home.packages = with pkgs; [
    systemd
    i3status

    # Desktop Applications
    alacritty
    dmenu
    scrot
    xclip

    # Lock Screen
    xsecurelock
    xss-lock

    # Audio Controls
    pulseaudio
    playerctl

    # Font
    (nerdfonts.override { fonts = [ "SourceCodePro" ]; })
  ];

  home.file.".background-image" = {
    enable = true;
    source = (root + "/wallpaper.jpg");
  };
}
