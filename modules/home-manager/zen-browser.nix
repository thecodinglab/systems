{
  config,
  pkgs,
  lib,
  ...
}:
{
  options.custom.zen-browser = {
    enable = lib.mkEnableOption "enable zen-browser";
  };

  config = lib.mkIf config.custom.zen-browser.enable {
    home.packages = lib.optional pkgs.stdenv.isLinux pkgs.zen-browser;

    xdg.mimeApps.defaultApplications = {
      "x-scheme-handler/http" = [ "zen-browser.desktop" ];
      "x-scheme-handler/https" = [ "zen-browser.desktop" ];
      "x-scheme-handler/chrome" = [ "zen-browser.desktop" ];
      "text/html" = [ "zen-browser.desktop" ];
      "application/x-extension-htm" = [ "zen-browser.desktop" ];
      "application/x-extension-html" = [ "zen-browser.desktop" ];
      "application/x-extension-shtml" = [ "zen-browser.desktop" ];
      "application/xhtml+xml" = [ "zen-browser.desktop" ];
      "application/x-extension-xhtml" = [ "zen-browser.desktop" ];
      "application/x-extension-xht" = [ "zen-browser.desktop" ];
    };
  };
}
