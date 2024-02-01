{ pkgs, lib, ... }: {
  programs.kitty = {
    enable = true;

    font = {
      package = (pkgs.nerdfonts.override { fonts = [ "JetBrainsMono" ]; });
      name = "JetBrainsMono Nerd Font";
      size = lib.mkDefault 11;
    };

    settings = (import ./theme.nix) // {
      clipboard_control = "write-clipboard write-primary read-clipboard-ask read-primary-ask";
    };
  };
}
