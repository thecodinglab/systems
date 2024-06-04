{ pkgs, lib, ... }: {
  programs.kitty = {
    enable = true;

    font = {
      package = (pkgs.nerdfonts.override { fonts = [ "JetBrainsMono" ]; });
      name = "JetBrainsMono Nerd Font";
      size = lib.mkDefault 11;
    };

    settings = {
      dynamic_background_opacity = true;
      background_opacity = "0.8";
      background_blur = 8;

      clipboard_control = "write-clipboard write-primary read-clipboard-ask read-primary-ask";

      allow_remote_control = "socket-only";
      listen_on = "unix:/tmp/kitty";
    };
  };
}
