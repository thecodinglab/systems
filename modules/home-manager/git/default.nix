{ pkgs, lib, ... }: {
  programs.git = {
    enable = true;
    lfs.enable = true;

    userName = "Florian Walter";
    userEmail = "nairolf.retlaw@gmail.com";

    signing = {
      key = null;
      signByDefault = true;
    };

    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = "true";

      credential."https://github.com".helper = "${lib.getExe pkgs.gh} auth git-credential";
      credential."https://gist.github.com".helper = "${lib.getExe pkgs.gh} auth git-credential";
      credential."https://github.zhaw.ch".helper = "${lib.getExe pkgs.gh} auth git-credential";
      credential."https://gitlab.deepengine.io".helper = "${lib.getExe pkgs.glab} auth git-credential";
      credential."https://git.overleaf.com".helper = ''!f() { test "$1" = get && echo "password=$(op item get Overleaf --fields 'git auth token')"; }; f'';
    };
  };

  programs.gpg = {
    enable = true;
    package = pkgs.gnupg;
  };
}
