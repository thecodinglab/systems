{ pkgs, lib, ... }:
{
  services.nix-daemon.enable = true;
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  environment = {
    variables = {
      EDITOR = lib.getExe pkgs.neovim;
    };

    systemPackages = [
      pkgs.coreutils
      pkgs.neovim
    ];
  };
}
