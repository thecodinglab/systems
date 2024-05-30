{ lib, ... }: {
  options.nord = {
    enable = lib.mkEnableOption "enable catppuccin theme";
  };

  imports = [
    ./kitty.nix
    ./tmux.nix
  ];
}
