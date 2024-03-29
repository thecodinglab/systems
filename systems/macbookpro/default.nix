{ pkgs, root, ... }: {
  imports = [
    # System
    (root + "/modules/darwin/base")
    (root + "/modules/darwin/yabai")

    # User
    ./users/florian
  ];

  #######################
  # General             #
  #######################

  documentation.enable = true;
  documentation.man.enable = true;

  #######################
  # Applications        #
  #######################

  programs.zsh.enable = true;

  environment = {
    shells = [ pkgs.zsh ];
    loginShell = pkgs.zsh;

    variables = {
      TERMINAL = "${pkgs.alacritty}/bin/alacritty";
    };
  };

  programs.gnupg.agent.enable = true;

  #######################
  # Networking          #
  #######################

  networking = {
    computerName = "Florian’s MacBook Pro";
    hostName = "Florians-MacBook-Pro";
    localHostName = "Florians-MacBook-Pro";
  };
}
