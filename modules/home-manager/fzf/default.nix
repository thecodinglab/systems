{ pkgs, lib, ... }: {
  programs.fzf = {
    enable = true;
    defaultCommand = "${lib.getExe pkgs.fd} --type f";
  };

  home.packages = with pkgs; [
    fd
    silver-searcher
  ];
}
