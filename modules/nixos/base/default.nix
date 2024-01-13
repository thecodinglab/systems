{ pkgs, neovim-config, ... }:
let
  neovim = neovim-config.makeDistribution pkgs;
in
{
  nix.settings = {
    auto-optimise-store = true;
    experimental-features = [ "nix-command" "flakes" ];
  };

  environment = {
    variables = {
      EDITOR = "${neovim}/bin/nvim";
    };

    systemPackages = with pkgs; [
      coreutils
      neovim

      htop
    ];
  };
}
