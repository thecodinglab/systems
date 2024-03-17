{ pkgs, lib, root, ... }: {
  imports = [
    (root + "/modules/home-manager/fzf")
  ];

  programs = {
    zsh = {
      enable = true;

      enableCompletion = true;
      autosuggestion.enable = true;

      shellAliases = {
        ls = "${pkgs.coreutils}/bin/ls -l --color=auto --group-directories-first -I . -I ..";
        ip = "ip --color=auto";
      };

      oh-my-zsh = {
        enable = true;
        theme = "robbyrussell";
      };

      initExtra = builtins.concatStringsSep "\n" [
        # show user and host in prompt
        ''RPS1="%F{cyan}%m%f $RPS1"''

        (builtins.readFile ./scripts/nix-shell-indicator.sh)
      ];
    };

    fzf.enableZshIntegration = lib.mkDefault true;
    kitty.shellIntegration.enableZshIntegration = lib.mkDefault true;
  };

  home.packages = with pkgs; [
    coreutils
  ];
}
