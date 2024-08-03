{ pkgs, lib, ... }:
{
  nix = {
    settings = {
      auto-optimise-store = true;
    };

    extraOptions = ''
      experimental-features = nix-command flakes
    '';

    gc = {
      automatic = true;
      interval = [
        {
          Hour = 9;
          Minute = 0;
        }
      ];
    };
  };

  services.nix-daemon.enable = true;

  documentation = {
    enable = lib.mkDefault true;
    man.enable = lib.mkDefault true;
  };

  environment = {
    variables = {
      EDITOR = "nvim";
    };

    shells = [ pkgs.zsh ];
    loginShell = pkgs.zsh;

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
}
