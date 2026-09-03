{
  config,
  pkgs,
  lib,
  ...
}:
{
  options.custom.audio = {
    enable = lib.mkEnableOption "enable audio";
  };

  config = lib.mkIf config.custom.audio.enable {
    programs.dconf.enable = true;

    services.pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;

      wireplumber.extraConfig = {
        # Use software volume control for all ALSA devices. This prevents
        # hardware mixer quirks (like muffled audio on Realtek codecs) and
        # gives a consistent volume curve across all hardware.
        "10-alsa-soft-mixer" = {
          "monitor.alsa.rules" = [
            {
              matches = [ { "device.name" = "~alsa_card.*"; } ];
              actions.update-props."api.alsa.soft-mixer" = true;
            }
          ];
        };

        # Auto-connect A2DP profiles on Bluetooth devices so speakers and
        # receivers expose their audio profiles without a manual reconnect.
        "10-bluetooth-a2dp-autoconnect" = lib.mkIf config.hardware.bluetooth.enable {
          "monitor.bluez.rules" = [
            {
              matches = [ { "device.name" = "~bluez_card.*"; } ];
              actions.update-props."bluez5.auto-connect" = [
                "a2dp_sink"
                "a2dp_source"
              ];
            }
          ];
        };
      };
    };

    environment.systemPackages = [ pkgs.pulseaudio ];
  };
}
