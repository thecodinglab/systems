{
  pkgs,
  nixvim,
  neovim,
}:
{
  minimal = nixvim.legacyPackages.${pkgs.system}.makeNixvimWithModule {
    inherit pkgs;
    module = ./config/minimal.nix;
    extraSpecialArgs = {
      inherit (neovim.packages.${pkgs.system}) neovim;
    };
  };
  dev = nixvim.legacyPackages.${pkgs.system}.makeNixvimWithModule {
    inherit pkgs;
    module = ./config/dev.nix;
    extraSpecialArgs = {
      inherit (neovim.packages.${pkgs.system}) neovim;
    };
  };
}
