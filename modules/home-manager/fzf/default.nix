{ pkgs, ... }: {
  programs.fzf = {
    enable = true;
    defaultCommand = "${pkgs.fd} --type f";
  };

  home.packages = with pkgs; [
    fd
    silver-searcher
  ];
}
