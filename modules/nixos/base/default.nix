{ pkgs, neovim-config, ... }:
let
  neovim-pkg = neovim-config.packages.${pkgs.system}.default;
in
{
  nix.settings = {
    auto-optimise-store = true;
    experimental-features = [ "nix-command" "flakes" ];
  };

  environment = {
    variables = {
      EDITOR = "${neovim-pkg}/bin/nvim";
    };

    systemPackages = with pkgs; [
      coreutils
      neovim-pkg

      htop
    ];
  };
}
