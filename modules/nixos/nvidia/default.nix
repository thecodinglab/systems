{ pkgs, ... }: {
  environment.variables = {
    LIBVA_DRIVER_NAME = "nvidia";
  };

  nixpkgs.config.cudaSupport = true;

  hardware = {
    opengl = {
      enable = true;
      driSupport = true;
      driSupport32Bit = true;
    };

    nvidia = {
      modesetting.enable = true;
      powerManagement.enable = true;

      nvidiaSettings = true;

      open = false;

      package = config.boot.kernelPackages.nvidiaPackages.stable;
    };
  };
}
