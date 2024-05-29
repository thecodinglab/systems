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
      Unit = "dynamic-brightness.service";
      OnCalendar = "*-*-* *:0/5:00";
      Persistent = true;
    };

    wantedBy = [ "timers.target" ];
  };

  hardware.i2c.enable = true;
}
