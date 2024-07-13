{ pkgs, lib, ... }:
{
  nix = {
    settings = {
      auto-optimise-store = true;
      experimental-features = [ "nix-command" "flakes" ];
    };

    gc = {
      automatic = true;
      dates = "daily";
      options = "--delete-older-than 7d";
    };
  };

  documentation = {
    enable = true;
    dev.enable = true;
    man.enable = true;
  };

  environment = {
    variables = {
      EDITOR = lib.getExe pkgs.neovim;
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
}
