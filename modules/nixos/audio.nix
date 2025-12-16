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
    };

    environment.systemPackages = [ pkgs.pulseaudio ];
  };
}
