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
        format = "ssh";
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
        push.autoSetupRemote = "true";
        checkout.defaultRemote = "origin";
        branch.autoSetupMerge = "simple";
        worktree.guessRemote = "true";
        pull.rebase = "true";

        diff = {
          algorithm = "histogram"; # clearer diffs on moved/edited lines
          colorMoved = "plain"; # highlight moved blocks in diffs
          mnemonicPrefix = "true"; # i/ w/ c/ prefixes instead of a/ b/
        };
        commit.verbose = "true"; # include the diff in the commit message template
        column.ui = "auto"; # output in columns when possible
        branch.sort = "-committerdate"; # most recent branches first
        tag.sort = "-version:refname"; # sort version numbers as you would expect
        rerere = {
          enabled = "true"; # record and reuse conflict resolutions
          autoupdate = "true"; # apply stored conflict resolutions automatically
        };

        gpg = {
          format = "ssh";
          ssh = {
            program =
              if pkgs.stdenv.isDarwin then
                "/Applications/1Password.app/Contents/MacOS/op-ssh-sign"
              else
                lib.getExe' pkgs._1password-gui "op-ssh-sign";
            allowedSignersFile = toString (
              pkgs.writeText "git-ssh-allowed-signers" ''
                fw@florian-walter.ch ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILrUBNULG42gQY1Y0Na+DFocGXrr1dZYfIXIXrwpjcxG
              ''
            );
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

    programs.delta = {
      enable = true;
      enableGitIntegration = true;
    };

    programs.gpg = {
      enable = true;
      package = pkgs.gnupg;

      # Several keyservers so key lookups don't hang on a single dead one.
      dirmngrSettings = {
        keyserver = [
          "hkps://keyserver.ubuntu.com"
          "hkps://pgp.surfnet.nl"
          "hkps://keys.mailvelope.com"
          "hkps://keyring.debian.org"
          "hkps://pgp.mit.edu"
        ];
        connect-quick-timeout = "4";
      };
    };
  };
}
