{ ... }: {
  programs.zsh = {
    enable = true;

    enableCompletion = true;
    enableBashCompletion = true;

    ohMyZsh = {
      enable = true;
      theme = "robbyrussell";
    };

    autosuggestions.enable = true;
  };

  programs.fzf.fuzzyCompletion = true;
}
