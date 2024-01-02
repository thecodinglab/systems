{ pkgs, ... }: {
  programs.zsh = {
    enable = true;

    enableCompletion = true;
    enableAutosuggestions = true;

    shellAliases = {
      ls = "${pkgs.coreutils}/bin/ls -l --color=auto --group-directories-first -I . -I ..";
    };

    oh-my-zsh = {
      enable = true;
      theme = "robbyrussell";
    };

    initExtra = builtins.readFile ./scripts/nix-shell-indicator.sh;
  };

  programs.fzf.enableZshIntegration = true;

  home.packages = with pkgs; [
    coreutils
  ];
}
