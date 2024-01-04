{ pkgs, neovim-config, ... }:
let
  neovim-pkg = neovim-config.packages.${pkgs.system}.default;
in
{
  services.nix-daemon.enable = true;
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

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
