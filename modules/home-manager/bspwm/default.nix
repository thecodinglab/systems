{ pkgs, ... }: {
  xsession.windowManager.bspwm = {
    enable = true;

    monitors = {
      "^1" = [ "1" ];
      "^2" = [ "2" ];
      "^3" = [ "3" ];
    };

    settings = {
      border_width = 1;
      window_gap = 8;

      split_ratio = 0.6;
      borderless_monocle = true;
      gapless_monocle = true;

      focus_follows_pointer = true;
      pointer_follows_focus = true;
    };

    startupPrograms = [
      "${pkgs.numlockx}/bin/numlockx on"
      "${pkgs.xss-lock}/bin/xss-lock --transfer-sleep-lock -- ${pkgs.xsecurelock}/bin/xsecurelock"
    ];
  };

  services = {
    sxhkd = {
      enable = true;
      keybindings = {
        "super + Return" = "${pkgs.alacritty}/bin/alacritty";
        "super + d" = "${pkgs.dmenu}/bin/dmenu_run";
        "super + control + q" = "${pkgs.systemd}/bin/loginctl lock-session";

        # close currently focused application
        "super + shift + q" = "bspc node -c";

        # make sxhkd reload its configuration files:
        "super + Escape" = "pkill -USR1 -x sxhkd";

        # quit/restart bspwm
        "super + alt + {q,r}" = "bspc {quit,wm -r}";

        #######################
        # bspwm hotkeys       #
        #######################

        # alternate between the tiled and monocle layout
        "super + m" = "bspc desktop -l next";

        # swap the current node and the biggest window
        "super + g" = "bspc node -s biggest.window";

        #######################
        # focus / swap        #
        #######################

        # focus the node in the given direction
        "super + {_,shift + }{h,j,k,l}" = "bspc node -{f,s} {west,south,north,east}";

        # focus or send to the given desktop
        "super + {_,shift + }{1-9,0}" = "bspc {desktop -f,node -d} '{1-9,10}'";

        #######################
        # preselect           #
        #######################

        # preselect the direction
        "super + ctrl + {h,j,k,l}" = "bspc node -p {west,south,north,east}";

        # preselect the ratio
        "super + ctrl + {1-9}" = "bspc node -o 0.{1-9}";

        # cancel the preselection for the focused node
        "super + ctrl + space" = "bspc node -p cancel";

        #######################
        # move / resize       #
        #######################

        # expand a window by moving one of its side outward
        "super + alt + {h,j,k,l}" = "bspc node -z {left -20 0,bottom 0 20,top 0 -20,right 20 0}";

        # contract a window by moving one of its side inward
        "super + alt + shift + {h,j,k,l}" = "bspc node -z {right -20 0,top 0 20,bottom 0 -20,left 20 0}";


        #######################
        # audio               #
        #######################

        # volume
        "XF86AudioRaiseVolume" = "${pkgs.pulseaudio}/bin/pactl set-sink-volume @DEFAULT_SINK@ +5%";
        "XF86AudioLowerVolume" = "${pkgs.pulseaudio}/bin/pactl set-sink-volume @DEFAULT_SINK@ -5%";
        "XF86AudioMute" = "${pkgs.pulseaudio}/bin/pactl set-sink-mute @DEFAULT_SINK@ toggle";
        "XF86AudioMicMute" = "${pkgs.pulseaudio}/bin/pactl set-source-mute @DEFAULT_SOURCE@ toggle";

        # navigation
        "XF86AudioPlay" = "${pkgs.playerctl}/bin/playerctl play-pause";
        "XF86AudioNext" = "${pkgs.playerctl}/bin/playerctl next";
        "XF86AudioPrev" = "${pkgs.playerctl}/bin/playerctl previous";
      };
    };

    polybar = {
      enable = true;
      package = pkgs.polybarFull;

      script = ''
        DISPLAYS=$(${pkgs.xorg.xrandr}/bin/xrandr --query | ${pkgs.gnugrep}/bin/grep " connected" | ${pkgs.coreutils}/bin/cut -d" " -f1)

        kill -9 $(pidof polybar)
        for m in $DISPLAYS; do
          MONITOR=$m polybar --reload default &
        done
      '';

      settings = {
        colors = {
          red = "#e46c67";
          red10 = "#cd615d";
          red20 = "#b65652";
          red30 = "#a04c48";
          red40 = "#89413e";
          red50 = "#723634";
          red60 = "#5b2b29";
          red70 = "#44201f";
          red80 = "#2e1615";
          red90 = "#170b0a";

          blue = "#7cb1ec";

          fg = "#c5c8c6";
          fg10 = "#b1b4b2";
          fg20 = "#9ea09e";
          fg30 = "#8a8c8b";
          fg40 = "#767877";
          fg50 = "#636463";
          fg60 = "#4f504f";
          fg70 = "#3b3c3b";
          fg80 = "#272828";
          fg90 = "#141414";

          bg = "#1d1f21";
          bg10 = "#343537";
          bg20 = "#4a4c4d";
          bg30 = "#616264";
          bg40 = "#77797a";
          bg50 = "#8e8f90";
          bg60 = "#a5a5a6";
          bg70 = "#bbbcbc";
          bg80 = "#d2d2d3";
          bg90 = "#e8e9e9";
        };

        "bar/base" = {
          width = "100%";
          height = "16pt";

          background = "\${colors.bg}";
          foreground = "\${colors.fg}";

          font = [ "SauceCodePro Nerd Font:size=10;2" ];

          cursor-click = "pointer";

          padding-left = 0;
          padding-right = 0;
          module-margin-left = 0;
          module-margin-right = 0;

          modules-left = "workspaces";
          modules-right = "filesystem space wifi space lan space pulseaudio space memory space cpu space time space";

          wm-restack = "bspwm";
        };

        "bar/default" = {
          "inherit" = "bar/base";

          monitor = "\${env:MONITOR}";
        };

        "module/workspaces" = {
          type = "internal/bspwm";
          pin.workspaces = true;

          label-focused = "%name%";
          label-focused-background = "\${colors.bg10}";
          label-focused-padding = 1;

          label-urgent = "%name%";
          label-urgent-background = "\${colors.red50}";
          label-urgent-padding = 1;

          label-occupied = "%name%";
          label-occupied-padding = 1;

          label-empty = "%name%";
          label-empty-padding = 1;
        };

        "module/time" = {
          type = "internal/date";
          interval = 1;

          date = "%d.%m.%Y";
          time = "%H:%M";

          label = "%date% %time%";
          label-foreground = "\${colors.fg}";
        };

        "module/cpu" = {
          type = "internal/cpu";

          format-prefix = "  ";

          label-foreground = "\${colors.fg}";
          label-warn-foreground = "\${colors.red}";
        };

        "module/memory" = {
          type = "internal/memory";

          format-prefix = "  ";

          label = "%gb_free%";
          label-foreground = "\${colors.fg}";

          label-warn = "%gb_free%";
          label-warn-foreground = "\${colors.red}";
        };

        "module/pulseaudio" = {
          type = "internal/pulseaudio";
          format-volume = "<ramp-volume> <label-volume>";

          label-volume = "%percentage%%";
          label-volume-foreground = "\${colors.fg}";

          label-muted = "󰝟";
          label-muted-foreground = "\${colors.red}";

          ramp-volume = [ "󰕿" "󰖀" "󰕾" ];
        };

        "module/lan" = {
          type = "internal/network";
          interval = 5;
          interface = "enp14s0";
          interface-type = "wired";

          format-connected = "<label-connected>";
          format-disconnected = "<label-disconnected>";

          label-connected = "󰛳  %local_ip% (%linkspeed%)";
          label-connected-foreground = "\${colors.fg}";

          label-disconnected = "󰅛";
          label-disconnected-foreground = "\${colors.red}";
        };

        "module/wifi" = {
          type = "internal/network";
          interval = 5;
          interface = "wlp12s0";
          interface-type = "wireless";

          format-connected = "<ramp-signal> <label-connected>";
          format-disconnected = "<label-disconnected>";

          label-connected = " %local_ip% (%signal%%)";
          label-connected-foreground = "\${colors.fg}";

          label-disconnected = "󰤭";
          label-disconnected-foreground = "\${colors.red}";

          ramp-signal = [ "󰤯" "󰤟" "󰤢" "󰤥" "󰤨" ];
        };

        "module/filesystem" = {
          type = "internal/fs";
          mount = [ "/" "/media/data" ];

          label-mounted = "%mountpoint% %free%";
        };

        "module/space" = {
          type = "custom/text";
          format = "  ";
        };

        "module/wide-space" = {
          type = "custom/text";
          format = "   ";
        };



        # settings = {
        # screenchange-reload = true;
        # pseudo-transparency = false;
        # };

        # "bar/main" = {
        #   width = "100%";
        #   height = "24pt";
        #   radius = 6;
        #
        #   modules = {
        #     left = "bspwm";
        #   };
        # };
        #
        # "module/bspwm" = {
        #   type = "internal/bspwm";
        #   pin.workspaces = true;
        # };
      };
    };
  };
}
