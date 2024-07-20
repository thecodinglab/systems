{
  config,
  pkgs,
  lib,
  ...
}:
{
  options.custom.dynamic-brightness = {
    enable = lib.mkEnableOption "enable dynamic brightness service to automatically adjust monitor brightness based on time of day";
  };

  config = lib.mkIf config.custom.dynamic-brightness.enable {
    systemd.services.dynamic-brightness = {
      enable = true;
      requires = [ "graphical.target" ];

      serviceConfig = {
        Type = "oneshot";
        DynamicUser = "yes";
        Group = "i2c";
      };

      script = ''
        LAT=47.3769N
        LON=8.5417E

        MIN_BRIGHTNESS=10
        MAX_BRIGHTNESS=75
        INCREMENTS=1

        SUNWAIT_BASE="sunwait list 1 $LAT $LON angle 2"

        CURRENT=$(date +%s)
        SUNRISE=$(date -d "$($SUNWAIT_BASE rise)" +%s)
        SUNSET=$(date -d "$($SUNWAIT_BASE set)" +%s)

        MINUTES_BEFORE_SUNRISE=$(((SUNRISE - CURRENT) / 60))
        MINUTES_AFTER_SUNSET=$(((CURRENT - SUNSET) / 60))

        if [ $MINUTES_BEFORE_SUNRISE -gt 0 ]; then
          BRIGHTNESS=$((MAX_BRIGHTNESS - MINUTES_BEFORE_SUNRISE * INCREMENTS))
        elif [ $MINUTES_AFTER_SUNSET -gt 0 ]; then
          BRIGHTNESS=$((MAX_BRIGHTNESS - MINUTES_AFTER_SUNSET * INCREMENTS))
        else
          BRIGHTNESS=$MAX_BRIGHTNESS
        fi

        BRIGHTNESS=$((BRIGHTNESS < MIN_BRIGHTNESS ? MIN_BRIGHTNESS : BRIGHTNESS))
        BRIGHTNESS=$((BRIGHTNESS > MAX_BRIGHTNESS ? MAX_BRIGHTNESS : BRIGHTNESS))

        for MONITOR in $(ddcutil detect --terse | grep I2C | sed -e 's/.*-//'); do
          ddcutil -b $MONITOR setvcp 10 $BRIGHTNESS
        done
      '';

      path = with pkgs; [
        ddcutil
        sunwait
      ];
    };

    systemd.timers.dynamic-brightness = {
      enable = true;

      timerConfig = {
        Unit = "dynamic-brightness.service";
        OnCalendar = "*-*-* *:0/5:00";
        Persistent = true;
      };

      wantedBy = [ "timers.target" ];
    };

    hardware.i2c.enable = true;
  };
}
