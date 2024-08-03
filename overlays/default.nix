{ inputs }:
{
  additions = final: _prev: import ../pkgs final;

  modifications =
    final: _prev:
    let
      stable = import inputs.nixpkgs-stable {
        inherit (final) system;
        inherit (final) config;
      };
    in
    {
      _1password = stable._1password;
      _1password-gui = stable._1password-gui;
      neovim = inputs.neovim-config.packages.${final.system}.default;
    };
}
