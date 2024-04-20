{ pkgs, ... }:
{
  services.nix-daemon.enable = true;
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  environment = {
    variables = {
      EDITOR = "${pkgs.neovim}/bin/nvim";
    };

    systemPackages = [
      pkgs.coreutils
      pkgs.htop

      pkgs.neovim
    ];
  };
}
