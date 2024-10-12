{
  pkgs,
  nixvim,
}:
{
  minimal = nixvim.legacyPackages.${pkgs.system}.makeNixvimWithModule {
    inherit pkgs;
    module = ./config/minimal.nix;
  };
  dev = nixvim.legacyPackages.${pkgs.system}.makeNixvimWithModule {
    inherit pkgs;
    module = ./config/dev.nix;
  };
}
