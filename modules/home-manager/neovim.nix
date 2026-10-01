{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.custom.neovim;
in
{
  options.custom.neovim = {
    enable = lib.mkEnableOption "the nixvim based neovim";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.neovim-dev;
      defaultText = lib.literalExpression "pkgs.neovim-dev";
      description = "nixvim package to install; it has to provide `extend`.";
    };

    # Applied in one `extend` call, so several feature sets can each add
    # plugins while only a single nvim ends up in home.packages.
    extensions = lib.mkOption {
      type = lib.types.listOf lib.types.deferredModule;
      default = [ ];
      description = "nixvim modules added on top of `package`.";
    };

    finalPackage = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
      description = "`package` with all `extensions` applied.";
    };
  };

  config = lib.mkIf cfg.enable {
    custom.neovim.finalPackage =
      if cfg.extensions == [ ] then cfg.package else cfg.package.extend { imports = cfg.extensions; };

    home.packages = [ cfg.finalPackage ];
  };
}
