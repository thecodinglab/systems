{
  pkgs,
  nixvim,
}:
{
  minimal = nixvim.legacyPackages.${pkgs.stdenv.hostPlatform.system}.makeNixvimWithModule {
    inherit pkgs;
    module = ./config/minimal.nix;
  };
  dev = nixvim.legacyPackages.${pkgs.stdenv.hostPlatform.system}.makeNixvimWithModule {
    inherit pkgs;
    module = ./config/dev.nix;
  };
}
