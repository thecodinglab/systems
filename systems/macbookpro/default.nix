{ pkgs, ... }: {
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  #######################
  # General             #
  #######################

  documentation.enable = true;
  documentation.man.enable = true;

  services.nix-daemon.enable = true;

  #######################
  # Environment         #
  #######################

  programs.zsh.enable = true;

  environment = {
    shells = [ pkgs.zsh ];
    loginShell = pkgs.zsh;

    variables = {
      TERMINAL = pkgs.alacritty;
      EDITOR = pkgs.neovim;
    };
  };

  #######################
  # Applications        #
  #######################

  environment.systemPackages = with pkgs; [
    # Mandatory System Management CLIs
    htop
    neovim
    coreutils
  ];

  #######################
  # Networking          #
  #######################

  networking = {
    computerName = "Florian’s MacBook Pro";
    hostName = "Florians-MacBook-Pro";
    localHostName = "Florians-MacBook-Pro";
  };
}
