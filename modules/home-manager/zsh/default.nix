{ pkgs, lib, ... }: {
  imports = [ ../fzf ];

  programs = {
    zsh = {
      enable = true;

      enableCompletion = true;
      autosuggestion.enable = true;

      defaultKeymap = "viins";

      shellAliases = {
        ls = "${pkgs.coreutils}/bin/ls -l --color=auto --group-directories-first -I . -I ..";
        ip = "ip --color=auto";
      };

      initExtra = builtins.concatStringsSep "\n" [
        ''
          PROMPT="%(?:%F{green}%1{➜%}:%F{red}%1{➜%}) %F{cyan}%~%f "
          RPS1="%F{cyan}%n@%m%f"
        ''

        (builtins.readFile ./scripts/nested-shell-indicator.sh)
      ];
    };

    fzf.enableZshIntegration = lib.mkDefault true;
    kitty.shellIntegration.enableZshIntegration = lib.mkDefault true;
  };

  home.packages = with pkgs; [
    coreutils
  ];
}
