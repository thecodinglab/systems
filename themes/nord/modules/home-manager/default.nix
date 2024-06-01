{ lib, ... }: {
  options.nord = {
    enable = lib.mkEnableOption "enable catppuccin theme";
  };

  imports = [
    ./dunst.nix
    ./hyprland.nix
    ./kitty.nix
    ./tmux.nix
    ./tofi.nix
    ./waybar.nix
    ./zathura.nix
  ];
}
