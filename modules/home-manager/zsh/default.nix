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

          dt = "devtools";
          ds = "devtools switch";

          vi = "nvim";
          vim = "nvim";
          view = "nvim -R";
          vimdiff = "nvim -d";
          ex = "nvim -e";
        };
      };

      # In the terminal's colours, and only three of them: the ink for what you
      # are looking at, the comment grey for what is only context, and a
      # colour only when it says something -- red when the last command
      # failed, the accent while vi mode is on.
      starship = {
        enable = true;

        settings = {
          format = (if config.custom.zsh.hostname then "$hostname " else "") + "$os $directory$character ";
          right_format = "$cmd_duration$shlvl$direnv";
          add_newline = false;

          character = {
            format = "$symbol";
            success_symbol = "[➜](bold)";
            error_symbol = "[➜](bold red)";
            vimcmd_symbol = "[➜](bold blue)";
          };

          os = {
            disabled = false;
            style = "bright-black";
            symbols = {
              Macos = " ";
              NixOS = " ";
            };
          };

          directory.style = "bold";

          username = {
            format = "$user";
            show_always = true;
          };

          hostname = {
            format = "[$hostname]($style)";
            ssh_only = false;
            style = "bright-black";
          };

          shlvl = {
            # TODO: add counter
            disabled = false;
            format = "[$symbol]($style) ";
            symbol = "";
            style = "bright-black";
            threshold = 3;
          };

          direnv.style = "bright-black";

          cmd_duration = {
            format = "[$duration]($style) ";
            style = "bright-black";
          };
        };
      };
    };

    home.packages = [ pkgs.coreutils ];
  };
}
