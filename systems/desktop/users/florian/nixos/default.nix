{ config, lib, pkgs, ... }:
{
  users.users.florian = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];

    shell = pkgs.zsh;

    packages = with pkgs; [
      # Desktop Applications
      _1password-gui
      spotify
    ];
  };
}
