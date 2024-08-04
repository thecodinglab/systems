{ pkgs, nixvim, ... }:
{
  package = nixvim.legacyPackages.${pkgs.system}.makeNixvimWithModule {
    inherit pkgs;
    module = ./config.nix;
  };

  options.programs.nixvim = pkgs.callPackage ./config.nix { };
}
