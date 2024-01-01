{ pkgs, ... }: {
  systemd.services.dynamic-brightness = {
    enable = true;
    requires = [ "graphical.target" ];

    serviceConfig = {
      Type = "oneshot";
      DynamicUser = "yes";
      Group = "i2c";
    };

    script = builtins.readFile ./scripts/update-brigtness.sh;
    path = with pkgs; [
      ddcutil
      sunwait
    ];
  };

  systemd.timers.dynamic-brightness = {
    enable = true;

    timerConfig = {
      OnCalendar = "*-*-* *:*:00";
      Unit = "dynamic-brightness.service";
    };

    wantedBy = [ "timers.target" ];
  };
}
