# every file in ./packages becomes a home assistant package of the same name,
# rendered to packages/<name>.yaml, every file or directory in ./dashboards a
# yaml mode dashboard rendered to dashboards/<name>.yaml, and ./www (the
# dashboard cards) is copied to www/. deploy.nix puts each of them into its
# directory in `targets`
{ pkgs }:
let
  inherit (pkgs) lib;

  # where deploy.nix puts each part, relative to the config directory
  targets = {
    packages = "packages/nix";
    dashboards = "dashboards/nix";
    www = "www/nix";
  };

  # what every package and dashboard gets as arguments
  entities = import ./entities.nix;
  args = import ./lib.nix { inherit lib entities; } // {
    inherit lib entities;
    # the dashboard files as home assistant needs them in its config and the
    # url /local serves www/ at
    dashboardFile = name: "${targets.dashboards}/${name}.yaml";
    wwwUrl = "/local/${lib.removePrefix "www/" targets.www}";
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

  # file or directory name without .nix
  dashboards = lib.mapAttrs' (file: _: {
    name = lib.removeSuffix ".nix" file;
    value = import ./dashboards/${file} args;
  }) (builtins.readDir ./dashboards);

  render = dir: name: value: ''
    remarshal --from json --to yaml-1.1 ${pkgs.writeText "${name}.json" (toJSON value)} $out/${dir}/${name}.yaml
  '';
in
pkgs.runCommand "home-assistant-config"
  {
    nativeBuildInputs = [ pkgs.remarshal ];
    passthru = { inherit targets; };
  }
  (
    ''
      mkdir -p $out/packages $out/dashboards $out/www
    ''
    + lib.concatStrings (lib.mapAttrsToList (render "packages") packages)
    + lib.concatStrings (lib.mapAttrsToList (render "dashboards") dashboards)
    + ''
      cp -r ${./www}/. $out/www/

      # browsers keep /local files for a month, loader.js imports the cards
      # with this appended so a deploy reaches them right away
      (cd $out/www && find . -type f | sort | xargs sha256sum | sha256sum | cut -c1-12) > $out/www/version
    ''
  )
