{ ... }: {
  services.apcupsd = {
    enable = true;
    configText = ''
      UPSCABLE usb
      UPSTYPE usb
      DEVICE /dev/usb/hid/hiddev[0-9]

      ONBATTERYDELAY 6
      BATTERYLEVEL 5
      MINUTES 3
      TIMEOUT 10
    '';
  };
}
