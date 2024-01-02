{ pkgs, lib, ... }:
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
      "wireless wlp4s0" = {
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
}
