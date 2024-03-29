{ ... }: {
  services.openssh = {
    enable = true;

    extraConfig = ''
      AcceptEnv TMUX
    '';
  };

  programs.ssh.startAgent = true;
}
