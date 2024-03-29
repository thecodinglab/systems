{ pkgs, lib, ... }: lib.mkIf pkgs.stdenv.isLinux {
  xdg.configFile = {
    "clipcat/clipcatd.toml" = {
      enable = true;
      source = ./config/clipcatd.toml;
    };

    "clipcat/clipcatctl.toml" = {
      enable = true;
      source = ./config/clipcatctl.toml;
    };
  };
}
