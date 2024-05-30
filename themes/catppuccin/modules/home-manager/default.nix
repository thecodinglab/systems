{ lib, ... }: {
  options.catppuccin = {
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
  };

  imports = [
    ./tmux.nix
    ./kitty.nix
  ];
}
