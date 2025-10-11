{ inputs }:
{
  additions =
    final: prev:
    import ../pkgs {
      pkgs = prev;
      inherit inputs;
    };

  modifications =
    final: prev:
    let
      stable = import inputs.nixpkgs-stable {
        inherit (final) system;
        inherit (final) config;
      };

      bleeding = import inputs.nixpkgs-bleeding {
        inherit (final) system;
        inherit (final) config;
      };
    in
    {
      # stable packages
      plex = stable.plex;

      # bleeding packages
      claude-code = bleeding.claude-code;

      # external packages
      vicinae = inputs.vicinae.packages.${prev.system}.default;
    };
}
