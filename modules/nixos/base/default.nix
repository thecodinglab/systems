{ pkgs, neovim-config, ... }:
let
  neovim = neovim-config.packages.${pkgs.system}.default;
in
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
      EDITOR = "${neovim}/bin/nvim";
    };

    systemPackages = [
      pkgs.coreutils
      pkgs.htop

      neovim
    ];
  };
}
