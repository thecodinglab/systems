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
      };

      starship = {
        enable = true;

        settings = {
          format = "$character $directory";
          right_format = "$cmd_duration$shlvl[$username@$hostname](cyan)";
          add_newline = false;

          character = {
            format = "$symbol";
            success_symbol = "[➜](bold green)";
            error_symbol = "[➜](bold red)";
            vimcmd_symbol = "[➜](bold purple)";
          };

          username = {
            format = "$user";
            show_always = true;
          };

          hostname = {
            format = "$hostname";
            ssh_only = false;
          };

          shlvl = {
            # TODO: add counter
            disabled = false;
            format = "[$symbol]($style) ";
            symbol = "";
            threshold = 3;
          };

          cmd_duration = {
            format = "[$duration](bold yellow) ";
          };
        };
      };
    };

    home.packages = [ pkgs.coreutils ];
  };
}
