{
  config,
  pkgs,
  lib,
  ...
}:
{
  options.custom.fzf = {
    enable = lib.mkEnableOption "enable fzf";
  };

  config = lib.mkIf config.custom.fzf.enable {
    programs.fzf = {
      enable = true;
      defaultCommand = "${lib.getExe pkgs.fd} --type f";

      # In the terminal's colours, so it switches with it (indices as laid
      # out by the ghostty module), and in no hue at all: the part of every
      # line the query matched is in the strong ink and bold, the row Return
      # takes is raised a step off the ground and pointed at in the strong
      # ink, and the chrome is the comment grey so the list stays the loudest
      # thing. fzf-lua in neovim runs with these too.
      colors = {
        fg = "-1";
        bg = "-1";
        hl = "21:bold";
        "fg+" = "-1:bold";
        "bg+" = "19";
        "hl+" = "21:bold";
        gutter = "-1";
        query = "-1:regular";
        prompt = "-1";
        pointer = "21";
        marker = "21";
        info = "8";
        spinner = "8";
        header = "8";
        border = "19";
        separator = "19";
        scrollbar = "19";
      };

      historyWidget.command = "";
    };

    home.packages = [
      pkgs.fd
      pkgs.ripgrep
    ];
  };
}
