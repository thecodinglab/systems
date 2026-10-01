# Linux desktop only parts of the user environment
{ pkgs, ... }:
{
  custom = {
    chromium.enable = true;
    hyprland.enable = true;
    zathura.enable = true;
  };

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "x-scheme-handler/http" = [ "helium.desktop" ];
      "x-scheme-handler/https" = [ "helium.desktop" ];
      "x-scheme-handler/chrome" = [ "helium.desktop" ];

      "x-scheme-handler/claude" = [ "com.anthropic.Claude.desktop" ];

      "text/html" = [ "helium.desktop" ];
      "application/x-extension-htm" = [ "helium.desktop" ];
      "application/x-extension-html" = [ "helium.desktop" ];
      "application/x-extension-shtml" = [ "helium.desktop" ];
      "application/xhtml+xml" = [ "helium.desktop" ];
      "application/x-extension-xhtml" = [ "helium.desktop" ];
      "application/x-extension-xht" = [ "helium.desktop" ];

      "application/pdf" = [ "org.pwmt.zathura.desktop" ];
      "application/oxps" = [ "org.pwmt.zathura.desktop" ];
      "application/epub+zip" = [ "org.pwmt.zathura.desktop" ];
      "application/x-fictionbook" = [ "org.pwmt.zathura.desktop" ];
    };
  };

  services.easyeffects.enable = true;

  # stylix only auto-enables its qt target when home-manager runs as a NixOS
  # module; keep qt unthemed as it was with the standalone home-manager
  stylix.targets.qt.enable = false;

  home.packages = [
    # Media
    pkgs.exiftool
    pkgs.ffmpeg
    pkgs.imv
    pkgs.mpv
    pkgs.spotify

    pkgs.easyeffects
    pkgs.obs-studio
    pkgs.remmina

    # Other
    pkgs.obsidian # on mac it is installed through `environment.systemPackage`
    pkgs.claude-desktop # on mac it is installed through `homebrew.casks`
    pkgs.helium # on mac it is installed through `homebrew.casks`
    pkgs.slack # on mac it is installed through `homebrew.casks`
    pkgs.fragments
  ];

  # 1password only installs its native messaging host for browsers it knows about
  xdg.configFile."net.imput.helium/NativeMessagingHosts/com.1password.1password.json".text =
    builtins.toJSON
      {
        name = "com.1password.1password";
        description = "1Password BrowserSupport";
        path = "/run/wrappers/bin/1Password-BrowserSupport";
        type = "stdio";
        allowed_origins = [
          "chrome-extension://hjlinigoblmkhjejkmbegnoaljkphmgo/"
          "chrome-extension://bkpbhnjcbehoklfkljkkbbmipaphipgl/"
          "chrome-extension://gejiddohjgogedgjnonbofjigllpkmbf/"
          "chrome-extension://khgocmkkpikpnmmkgmdnfckapcdkgfaf/"
          "chrome-extension://aeblfdkhhhdcdjpifhhbdiojplfjncoa/"
          "chrome-extension://dppgmdbiimibapkepcbdbmkaabgiofem/"
        ];
      };
}
