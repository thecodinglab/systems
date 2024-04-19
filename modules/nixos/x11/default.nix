{ pkgs, ... }: {
  services.autorandr.enable = true;

  services.xserver = {
    enable = true;
    autorun = true;

    # Keyboard Layout
    xkb = {
      layout = "us";
      options = "compose:rwin";
    };

    # Trackpad
    libinput.touchpad = {
      accelSpeed = "0.5";
      naturalScrolling = true;
    };

    # Monitor Arrangement (from nvidia-settings)
    screenSection = ''
      Option "metamodes" "DP-4: nvidia-auto-select +6000+0, DP-0.8: nvidia-auto-select +0+0, DP-2: nvidia-auto-select +2560+0"
    '';

    xrandrHeads = [
      { output = "DP-0.8"; primary = false; }
      { output = "DP-2"; primary = true; }
      { output = "DP-4"; primary = false; }
    ];

    videoDrivers = [ "nvidia" ];

    # Desktop Manager
    desktopManager = {
      xterm.enable = false;

      wallpaper = {
        combineScreens = false;
        mode = "fill";
      };
    };

    # Other
    excludePackages = with pkgs; [ xterm ];
  };

  # clipboard manager
  services.clipcat.enable = true;
}
