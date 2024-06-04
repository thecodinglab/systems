{ pkgs, ... }:
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

  environment = {
    variables = {
      EDITOR = "${pkgs.neovim}/bin/nvim";
    };

    systemPackages = [
      pkgs.coreutils
      pkgs.neovim
    ];

    pathsToLink = [
      "/share/zsh" # link zsh completions for system packages

      # link desktop portal definitions and applications
      "/share/xdg-desktop-portal"
      "/share/applications"
    ];
  };
}
