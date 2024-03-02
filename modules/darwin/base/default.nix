{ pkgs, neovim-config, ... }:
let
  neovim = neovim-config.packages.${pkgs.system}.default;
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

    systemPackages = [
      pkgs.coreutils
      pkgs.htop

      neovim
    ];
  };
}
