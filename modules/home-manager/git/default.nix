{ pkgs, lib, ... }: {
  programs.git = {
    enable = true;
    lfs.enable = true;

    userName = "Florian Walter";
    userEmail = "fw@florian-walter.ch";

    signing = {
      key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILrUBNULG42gQY1Y0Na+DFocGXrr1dZYfIXIXrwpjcxG";
      signByDefault = true;
    };

    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = "true";

      gpg = {
        format = "ssh";
        ssh = {
          program = lib.getExe' pkgs._1password-gui "op-ssh-sign";
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
      credential."https://git.overleaf.com".helper = ''!f() { test "$1" = get && echo "password=$(op item get Overleaf --fields 'git auth token')"; }; f'';
    };

    delta.enable = true;
  };

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
}
