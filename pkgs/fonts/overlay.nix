final: prev:
let
  sf = final.callPackage ./san-francisco.nix { };
in
{
  apple-font-sf-pro = sf.pro;
  apple-font-sf-compact = sf.compact;
  apple-font-sf-mono = sf.mono;
  apple-font-sf-new-york = sf.ny;
}
