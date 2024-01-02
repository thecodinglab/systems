{ pkgs, root, ... }: {
  imports = [
    (root + "/users/florian/darwin")
  ];

  #######################
  # General             #
  #######################

  documentation.enable = true;
  documentation.man.enable = true;

  services.nix-daemon.enable = true;
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  #######################
  # Environment         #
  #######################

  programs.zsh.enable = true;

  environment = {
    shells = [ pkgs.zsh ];
    loginShell = pkgs.zsh;

    variables = {
      TERMINAL = "${pkgs.alacritty}/bin/alacritty";
      EDITOR = "${pkgs.neovim}/bin/nvim";
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
