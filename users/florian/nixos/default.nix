{ config, lib, pkgs, ... }:
{
  users.users.florian = {
    isNormalUser = true;
    extraGroups = [ "wheel" "i2c" ];
    initialPassword = "changeme";

    shell = pkgs.zsh;

    packages = with pkgs; [
      # Desktop Applications
      _1password-gui
      spotify

      # Build Tools
      gcc
      gnumake
      cmake

      # Git
      git
      git-crypt
      gh
      glab
      smartgithg
    ];
  };
}
