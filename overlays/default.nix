{ inputs }:
{
  additions = final: prev: import ../pkgs (prev // inputs);

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
      incus = stable.incus;
      incus-lts = stable.incus-lts;
    };
}
