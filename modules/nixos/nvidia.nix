{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.custom.nvidia = {
    enable = lib.mkEnableOption "enable nvidia configurations";
  };

  config = lib.mkIf config.custom.nvidia.enable {
    environment.variables = {
      LIBVA_DRIVER_NAME = "nvidia";
    };

    services.xserver.videoDrivers = [ "nvidia" ];

    hardware = {
      graphics = {
        enable = true;
        enable32Bit = true;
        extraPackages = [
          pkgs.egl-wayland
          pkgs.nvidia-vaapi-driver
        ];
      };

      nvidia = {
        modesetting.enable = true;
        powerManagement.enable = true;

        open = true;
        nvidiaSettings = true;

        package = config.boot.kernelPackages.nvidiaPackages.stable;
      };
    };
  };
}
