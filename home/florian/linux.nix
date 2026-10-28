# Linux desktop only parts of the user environment
{
  lib,
  pkgs,
  osConfig,
  ...
}:
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

  # profiles and accounts are managed in thunderbird itself, only the theme is
  # installed through policies (enable it once under Add-ons and Themes)
  programs.thunderbird = {
    enable = true;
    policies.ExtensionSettings."{f6d05f0c-39a8-5c4d-96dd-4852202a8244}" = {
      installation_mode = "force_installed";
      install_url = "file://${
        pkgs.fetchurl {
          name = "catppuccin-mocha-blue.xpi";
          url = "https://raw.githubusercontent.com/catppuccin/thunderbird/0289f3bd9566f9666682f66a3355155c0d0563fc/themes/mocha/mocha-blue.xpi";
          hash = "sha256-ApuqSR6GWY1guajM+laozGNBVMq9BWlcKz16hbeFoLU=";
        }
      }";
    };
  };

  # local IMAP/SMTP for thunderbird, keeps its login in gnome-keyring
  services.protonmail-bridge.enable = true;

  # mpv decodes in software unless told otherwise
  programs.mpv = {
    enable = true;
    config = {
      vo = "gpu-next";
      gpu-api = "vulkan";
      # NVDEC/Vulkan video with copy-free interop, software fallback for
      # codecs the GPU can't do
      hwdec = "auto-safe";
      profile = "high-quality";
      video-sync = "display-resample";
      interpolation = true;
    };
  };

  # stylix only auto-enables its qt target when home-manager runs as a NixOS
  # module; keep qt unthemed as it was with the standalone home-manager
  stylix.targets.qt.enable = false;

  home.packages = [
    # Media
    pkgs.exiftool
    pkgs.ffmpeg
    pkgs.imv
    pkgs.spotify

    pkgs.easyeffects
    pkgs.obs-studio
    pkgs.remmina

    # Other
    pkgs.claude-desktop # on mac it is installed through `homebrew.casks`
    # on mac it is installed through `homebrew.casks`
    (pkgs.helium.override {
      # chromium does not use VA-API on nvidia unless explicitly asked to, so
      # all video falls back to software decoding and HEVC (hardware only on
      # linux) does not play at all
      commandLineArgs = lib.optionals osConfig.custom.nvidia.enable [
        "--enable-features=VaapiVideoDecoder,VaapiOnNvidiaGPUs,AcceleratedVideoDecodeLinuxGL"
      ];
    })
    pkgs.slack # on mac it is installed through `homebrew.casks`
    pkgs.fragments
    # `gcc-unwrapped` in the nixpkgs build inputs only ships `libstdc++.a`, so a
    # second, static copy of libstdc++ gets linked into the binary and the
    # proprietary Bambu network plugin aborts with `free(): invalid size` on
    # startup; drop it until https://github.com/NixOS/nixpkgs/pull/557126 lands
    (pkgs.orca-slicer.overrideAttrs (old: {
      buildInputs = lib.remove pkgs.gcc-unwrapped old.buildInputs;
    }))
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
