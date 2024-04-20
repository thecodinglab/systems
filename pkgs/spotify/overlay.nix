final: prev: {
  spotify = prev.callPackage ./default.nix {
    spotify = prev.spotify;
  };
}
