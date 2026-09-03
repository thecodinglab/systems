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
      # nvidia-vaapi-driver: talk to the kernel driver directly instead of
      # going through EGL, which is faster and works with the proprietary driver.
      NVD_BACKEND = "direct";
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    };

    services.xserver.videoDrivers = [ "nvidia" ];

    hardware = {
      graphics = {
        enable = true;
        extraPackages = [
          pkgs.egl-wayland
          pkgs.nvidia-vaapi-driver
        ];
      };

      nvidia = {
        modesetting.enable = true;
        powerManagement.enable = true;

        nvidiaSettings = true;

        package = lib.mkDefault config.boot.kernelPackages.nvidiaPackages.stable;
      };
    };
  };
}
