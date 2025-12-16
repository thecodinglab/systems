{
  pkgs,
  inputs,
}:
let
  deps = import ../_sources/generated.nix {
    inherit (pkgs)
      fetchgit
      fetchurl
      fetchFromGitHub
      dockerTools
      ;
  };

  callPackage = input: (args: pkgs.callPackage input ({ inherit deps; } // args));

  mkPrefix =
    prefix: attrs:
    builtins.listToAttrs (
      pkgs.lib.mapAttrsToList (name: value: {
        name = "${prefix}-${name}";
        inherit value;
      }) attrs
    );
in
{
  zen-browser = callPackage ./zen-browser.nix { };
  helium = callPackage ./helium.nix { };
}
// mkPrefix "neovim" (
  import ./neovim/package.nix {
    inherit pkgs;
    inherit (inputs) nixvim;
  }
)
// import ./fonts/san-francisco.nix { inherit pkgs; }
