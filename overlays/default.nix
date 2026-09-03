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
        inherit (final.stdenv.hostPlatform) system;
        inherit (final) config;
      };

      bleeding = import inputs.nixpkgs-bleeding {
        inherit (final.stdenv.hostPlatform) system;
        inherit (final) config;
      };
    in
    {
      # stable packages
      plex = stable.plex;

      # bleeding packages
      antigravity-cli = bleeding.antigravity-cli;
      claude-code = bleeding.claude-code;
      codex = bleeding.codex;

      # external packages
    };
}
