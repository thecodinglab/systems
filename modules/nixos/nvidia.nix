{
  config,
  lib,
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
      # nvidia-vaapi-driver comes from hardware.nvidia.videoAcceleration and the
      # egl-wayland/egl-gbm platform libraries from the driver package itself
      graphics.enable = true;

      nvidia = {
        modesetting.enable = true;
        powerManagement.enable = true;
        videoAcceleration = true;

        nvidiaSettings = true;

        package = lib.mkDefault config.boot.kernelPackages.nvidiaPackages.stable;
      };
    };
  };
}
