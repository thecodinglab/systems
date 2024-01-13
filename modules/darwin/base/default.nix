{ pkgs, neovim-config, ... }:
let
  neovim = neovim-config.makeDistribution pkgs;
in
{
  services.nix-daemon.enable = true;
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

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
