{ pkgs, ... }: {
  programs.git = {
    enable = true;

    userName = "Florian Walter";
    userEmail = "nairolf.retlaw@gmail.com";

    signing = {
      key = null;
      signByDefault = true;
    };

    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = "true";
    };
  };

  programs.gpg = {
    enable = true;
    package = pkgs.gnupg;
  };
}
