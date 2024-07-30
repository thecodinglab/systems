{
  config,
  pkgs,
  lib,
  ...
}:
{
  options.custom.zsh = {
    enable = lib.mkEnableOption "enable zsh";
  };

  config = lib.mkIf config.custom.zsh.enable {
    programs = {
      zsh = {
        enable = true;
        enableCompletion = true;

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

      fzf.enableZshIntegration = config.custom.fzf.enable;
      kitty.shellIntegration.enableZshIntegration = config.custom.kitty.enable;
    };

    home.packages = [ pkgs.coreutils ];
  };
}
