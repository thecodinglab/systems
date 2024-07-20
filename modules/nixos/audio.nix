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
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
    };

    environment.systemPackages = [ pkgs.pulseaudio ];
  };
}
