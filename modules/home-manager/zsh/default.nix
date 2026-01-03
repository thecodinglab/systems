{
  config,
  pkgs,
  lib,
  ...
}:
{
  options.custom.zsh = {
    enable = lib.mkEnableOption "enable zsh";
    hostname = lib.mkEnableOption "enable hostname in prompt";
  };

  config = lib.mkIf config.custom.zsh.enable {
    programs = {
      zsh = {
        enable = true;
        enableCompletion = true;

        dotDir = "${config.xdg.configHome}/zsh";

        defaultKeymap = "viins";

        shellAliases = {
          ls = "${pkgs.coreutils}/bin/ls -l --color=auto --group-directories-first -I . -I ..";
          ip = "ip --color=auto";
        };
      };

      starship = {
        enable = true;

        settings = {
          format = (if config.custom.zsh.hostname then "$hostname " else "") + "$os $directory$character ";
          right_format = "$cmd_duration$shlvl$direnv";
          add_newline = false;

          character = {
            format = "$symbol";
            success_symbol = "[➜](bold green)";
            error_symbol = "[➜](bold red)";
            vimcmd_symbol = "[➜](bold purple)";
          };

          os = {
            disabled = false;
            style = "#777777";
            symbols = {
              Macos = " ";
              NixOS = " ";
            };
          };

          username = {
            format = "$user";
            show_always = true;
          };

          hostname = {
            format = "[$hostname]($style)";
            ssh_only = false;
            style = "#777777";
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
