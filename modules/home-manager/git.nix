{
  config,
  pkgs,
  lib,
  ...
}:
{
  options.custom.git = {
    enable = lib.mkEnableOption "enable git";
  };

  config = lib.mkIf config.custom.git.enable {
    programs.git = {
      enable = true;
      lfs.enable = true;

      signing = {
        key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILrUBNULG42gQY1Y0Na+DFocGXrr1dZYfIXIXrwpjcxG";
        signByDefault = true;
      };

      ignores = [
        ".direnv"
        ".envrc"
        ".DS_Store"
      ];

      settings = {
        user = {
          name = "Florian Walter";
          email = "fw@florian-walter.ch";
        };

        init.defaultBranch = "main";
        pull.rebase = "true";

        gpg = {
          format = "ssh";
          ssh = {
            program =
              if pkgs.stdenv.isDarwin then
                "${pkgs._1password-gui}/Applications/1Password.app/Contents/MacOS/op-ssh-sign"
              else
                lib.getExe' pkgs._1password-gui "op-ssh-sign";
            allowedSignersFile =
              let
                allowedSigners = pkgs.writeText "git-ssh-allowed-signers" ''
                  fw@florian-walter.ch ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILrUBNULG42gQY1Y0Na+DFocGXrr1dZYfIXIXrwpjcxG
                '';
              in
              "${allowedSigners}";
          };
        };

        credential."https://github.com".helper = "${lib.getExe pkgs.gh} auth git-credential";
        credential."https://gist.github.com".helper = "${lib.getExe pkgs.gh} auth git-credential";
        credential."https://github.zhaw.ch".helper = "${lib.getExe pkgs.gh} auth git-credential";
        credential."https://gitlab.deepengine.io".helper = "${lib.getExe pkgs.glab} auth git-credential";
        credential."https://git.overleaf.com".helper =
          ''!f() { test "$1" = get && echo "password=$(op item get Overleaf --fields 'git auth token')"; }; f'';
      };
    };

    programs.delta.enable = true;

    programs.gpg = {
      enable = true;
      package = pkgs.gnupg;
    };

    programs.lazygit = {
      enable = true;
      settings = {
        git.paging = {
          colorArg = "always";
          pager = "${lib.getExe pkgs.delta} --dark --paging=never";
        };
      };
    };
  };
}
