{ pkgs, ... }: {
  services =
    let
      yabai = "${pkgs.yabai}/bin/yabai";
    in
    {
      yabai = {
        enable = true;
        package = pkgs.yabai;

        config = {
          layout = "bsp";
          focus_follows_mouse = "autoraise";
          mouse_follows_focus = "on";

          top_padding = 8;
          bottom_padding = 8;
          left_padding = 8;
          right_padding = 8;
          window_gap = 8;

          split_ratio = 0.6;
        };

        extraConfig = ''
          ${yabai} -m rule --add app='Finder' manage=off
          ${yabai} -m rule --add app='System Settings' manage=off
          ${yabai} -m rule --add app='1Password' manage=off
          ${yabai} -m rule --add app='Spotify' manage=off

          ${yabai} -m rule --add app='mpv' manage=off
        '';
      };

      skhd = let mod = "alt"; in
        {
          enable = true;
          skhdConfig = ''
            ${mod} - 1 : ${yabai} -m space --focus 1
            ${mod} - 2 : ${yabai} -m space --focus 2
            ${mod} - 3 : ${yabai} -m space --focus 3
            ${mod} - 4 : ${yabai} -m space --focus 4
            ${mod} - 5 : ${yabai} -m space --focus 5
            ${mod} - 6 : ${yabai} -m space --focus 6
            ${mod} - 7 : ${yabai} -m space --focus 7
            ${mod} - 8 : ${yabai} -m space --focus 8
            ${mod} - 9 : ${yabai} -m space --focus 9
            ${mod} - 0 : ${yabai} -m space --focus 10

            ${mod} - n : ${yabai} -m space --create
            ${mod} - q : ${yabai} -m space --destroy

            ${mod} - h : ${yabai} -m window --focus west
            ${mod} - j : ${yabai} -m window --focus south
            ${mod} - k : ${yabai} -m window --focus north
            ${mod} - l : ${yabai} -m window --focus east

            shift + ${mod} - h : ${yabai} -m window --swap west
            shift + ${mod} - j : ${yabai} -m window --swap south
            shift + ${mod} - k : ${yabai} -m window --swap north
            shift + ${mod} - l : ${yabai} -m window --swap east
          
            ${mod} - f : ${yabai} -m window --toggle zoom-fullscreen
          '';
        };
    };
}
