{ inputs }:
{
  additions =
    final: prev:
    import ../pkgs {
      pkgs = prev;
      inherit inputs;
    };

  modifications =
    final: _prev:
    let
      stable = import inputs.nixpkgs-stable {
        inherit (final) system;
        inherit (final) config;
      };
    in
    {
      chatterino7 = stable.chatterino7;
    };
}
