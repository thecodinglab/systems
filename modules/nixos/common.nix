{ pkgs, lib, ... }:
{
  config = lib.mkIf pkgs.stdenv.isLinux {
    nix = {
      settings = {
        auto-optimise-store = true;
        experimental-features = [
          "nix-command"
          "flakes"
        ];
      };

      gc = {
        automatic = true;
        dates = "daily";
        options = "--delete-older-than 7d";
      };
    };

    time.timeZone = "Europe/Zurich";

    i18n = {
      supportedLocales = [
        "en_US.UTF-8/UTF-8"
        "de_CH.UTF-8/UTF-8"
      ];
      defaultLocale = "en_US.UTF-8";
      extraLocaleSettings = {
        LC_NUMERIC = "de_CH.UTF-8";
        LC_TIME = "de_CH.UTF-8";
        LC_MONETARY = "de_CH.UTF-8";
        LC_MEASUREMENT = "de_CH.UTF-8";
      };
    };

    documentation = {
      enable = lib.mkDefault true;
      dev.enable = lib.mkDefault true;
      man.enable = lib.mkDefault true;
      nixos.enable = lib.mkDefault true;
    };

    networking = {
      useNetworkd = true;
      nftables.enable = true;
      firewall.enable = true;
    };

    environment = {
      variables = {
        EDITOR = pkgs.lib.getExe pkgs.neovim;
      };

      shells = [ pkgs.zsh ];

      systemPackages = [
        pkgs.coreutils
        pkgs.neovim
      ];

      pathsToLink = [
        # link zsh completions for system packages
        "/share/zsh"
      ];
    };

    programs.zsh.enable = true;
    services.openssh.enable = true;
  };
}