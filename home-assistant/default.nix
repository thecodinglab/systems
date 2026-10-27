# every file in ./packages becomes a home assistant package of the same name,
# rendered to <name>.yaml and deployed to <config>/packages/nix (see deploy.nix)
{ pkgs }:
let
  inherit (pkgs) lib;

  # what every package gets as arguments
  entities = import ./entities.nix;
  args = import ./lib.nix { inherit lib entities; } // {
    inherit lib entities;
  };

  # like builtins.toJSON, but keeps ordered maps in order
  toJSON =
    value:
    let
      pair = name: value: "${builtins.toJSON name}:${toJSON value}";
    in
    if lib.isType "ordered" value then
      "{${
        lib.concatMapStringsSep "," (
          entry:
          let
            name = lib.head (lib.attrNames entry);
          in
          pair name entry.${name}
        ) value.entries
      }}"
    else if lib.isAttrs value then
      "{${lib.concatStringsSep "," (lib.mapAttrsToList pair value)}}"
    else if lib.isList value then
      "[${lib.concatMapStringsSep "," toJSON value}]"
    else
      builtins.toJSON value;

  # home assistant merges the maps of packages recursively and silently drops
  # empty maps and falsy list items on the way, so e.g. a selector without
  # options has to be `boolean = null` instead of `boolean = { }`
  checkMerge =
    path: value:
    if lib.isType "ordered" value then
      lib.all (checkMerge path) value.entries
    else if lib.isAttrs value then
      assert lib.assertMsg (
        value != { }
      ) "${path}: home assistant drops empty maps in packages, use null";
      lib.all (name: checkMerge "${path}.${name}" value.${name}) (lib.attrNames value)
    else if lib.isList value then
      lib.assertMsg (lib.all (
        item:
        !lib.elem item [
          null
          false
          0
          ""
          { }
          [ ]
        ]
      ) value) "${path}: home assistant drops falsy list items in packages"
    else
      true;

  # package names have to be slugs, home assistant skips the others with only a
  # warning
  slug =
    file:
    let
      name = lib.replaceStrings [ "-" ] [ "_" ] (lib.removeSuffix ".nix" file);
    in
    assert lib.assertMsg (
      builtins.match "[a-z0-9_]+" name != null
    ) "home-assistant/packages/${file}: ${name} is not a valid package name";
    name;

  packages = lib.mapAttrs' (
    file: _:
    let
      name = slug file;
      package = import ./packages/${file} args;
    in
    # list domains (automation) are concatenated as they are
    assert lib.all (
      domain: lib.isList package.${domain} || checkMerge "${name}.${domain}" package.${domain}
    ) (lib.attrNames package);
    {
      inherit name;
      value = package;
    }
  ) (builtins.readDir ./packages);
in
pkgs.runCommand "home-assistant-config" { nativeBuildInputs = [ pkgs.remarshal ]; } (
  ''
    mkdir $out
  ''
  + lib.concatStrings (
    lib.mapAttrsToList (name: package: ''
      remarshal --from json --to yaml-1.1 ${pkgs.writeText "${name}.json" (toJSON package)} $out/${name}.yaml
    '') packages
  )
)
