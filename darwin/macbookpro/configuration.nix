{ outputs, pkgs, ... }:
{
  nixpkgs.overlays = [
    outputs.overlays.additions
    outputs.overlays.modifications
  ];

  programs.gnupg.agent.enable = true;

  networking = {
    computerName = "Florian’s MacBook Pro";
    hostName = "Florians-MacBook-Pro";
    localHostName = "Florians-MacBook-Pro";
  };

  environment.systemPackages = [ pkgs.home-manager ];

  users.users.florian = {
    name = "florian";
    home = "/Users/florian/";
  };
}
