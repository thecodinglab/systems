{ pkgs, ... }: {
  programs.git = {
    enable = true;

    signing = {
      gpgPath = "${pkgs.gnupg}/bin/gpg";
      key = null;
      signByDefault = true;
    };
  };

  programs.gpg = {
    enable = true;
    package = pkgs.gnupg;
  };
}
