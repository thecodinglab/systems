{
  config,
  pkgs,
  lib,
  ...
}:
{
  options.custom.fzf = {
    enable = lib.mkEnableOption "enable fzf";
  };

  config = lib.mkIf config.custom.fzf.enable {
    programs.fzf = {
      enable = true;
      defaultCommand = "${lib.getExe pkgs.fd} --type f";
    };

    home.packages = [
      pkgs.fd
      pkgs.silver-searcher
    ];
  };
}
