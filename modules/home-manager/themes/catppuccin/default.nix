{ lib, ... }:
{
  options.custom.catppuccin = {
    enable = lib.mkEnableOption "enable catppuccin theme";
    flavor = lib.mkOption {
      type = lib.types.enum [
        "latte"
        "frappe"
        "macchiato"
        "mocha"
      ];
      default = "mocha";
      description = "catppuccin theme flavor";
    };
    accent = lib.mkOption {
      type = lib.types.enum [
        "blue"
        "flamingo"
        "green"
        "lavender"
        "maroon"
        "mauve"
        "peach"
        "pink"
        "red"
        "rosewater"
        "sapphire"
        "sky"
        "teal"
        "yellow"
      ];
      default = "sapphire";
      description = "catppuccin theme accent";
    };
  };

  imports = [
    ./bat.nix
    ./btop.nix
    ./delta.nix
    ./dunst.nix
    ./fzf.nix
    ./hyprland.nix
    ./kitty.nix
    ./lazygit.nix
    ./tmux.nix
    ./tofi.nix
    ./waybar.nix
    ./zathura.nix
  ];
}
