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
      gemini-cli = bleeding.gemini-cli;
      claude-code = bleeding.claude-code;
      codex = bleeding.codex;

      # external packages
    };
}
