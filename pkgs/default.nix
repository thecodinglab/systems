{
  pkgs,
  inputs,
}:
let
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
  zen-browser = pkgs.callPackage ./zen-browser { };
}
// mkPrefix "neovim" (
  import ./neovim/package.nix {
    inherit pkgs;
    inherit (inputs) nixvim;
  }
)
// import ./fonts/san-francisco.nix { inherit pkgs; }
