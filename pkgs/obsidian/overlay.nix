final: prev: {
  obsidian = prev.callPackage ./default.nix {
    obsidian = prev.obsidian;
  };
}
