# pushes the rendered packages, dashboards and cards to the home assistant os
# host over ssh (via the "Terminal & SSH" add-on), validates them through the
# api and reloads; an invalid config is rolled back before home assistant ever
# loads it
{ pkgs, config }:
let
  # part:directory pairs, see targets in default.nix
  targets = pkgs.lib.concatStringsSep " " (
    pkgs.lib.mapAttrsToList (part: dir: "${part}:${dir}") config.targets
  );
in
pkgs.writeShellApplication {
  name = "home-assistant-deploy";

  runtimeInputs = with pkgs; [
    curl
    gnutar
    jq
    openssh
    sops
  ];

  # the snippets passed to remote are meant to expand on the host
  excludeShellChecks = [
    "SC2016"
    "SC2029"
  ];

  text = ''
    HA_URL=''${HA_URL:-https://home.florian-walter.ch}
    HA_SSH=''${HA_SSH:-root@192.168.128.100}
    HA_CONFIG_DIR=''${HA_CONFIG_DIR:-/homeassistant}

    staging="$HA_CONFIG_DIR/.nix-deploy"

    token=$(sops -d --extract '["HOME_ASSISTANT_TOKEN"]' ${./secrets.yaml})

    api() {
      curl -fsS -X POST \
        -H @<(printf 'Authorization: Bearer %s\n' "$token") \
        -H 'Content-Type: application/json' \
        "$HA_URL/api/$1" "''${@:2}"
    }

    remote() {
      ssh "$HA_SSH" "set -eu; config='$HA_CONFIG_DIR'; staging='$staging'; targets='${targets}'; $1"
    }

    # warnings that are not in the baseline make the upload fail, a package
    # home assistant rejects only shows up as a warning
    check() {
      local result
      result=$(api config/core/check_config) || return 1
      if [ "$(jq -r .result <<<"$result")" != valid ]; then
        jq -r '.errors // empty' <<<"$result" >&2
        return 1
      fi
      jq -r '.warnings // empty' <<<"$result"
    }

    echo "checking the current configuration"
    baseline=$(check) || { echo "the current configuration is already invalid" >&2; exit 1; }

    remote '[ ! -e "$staging" ]' \
      || { echo "$staging is left over from an interrupted deploy, check and remove it" >&2; exit 1; }

    uploaded=
    rollback() {
      if [ -n "$uploaded" ]; then
        echo "rolling back" >&2
        # every target it can, even if one of them fails; the old files stay in
        # staging then
        remote '
          set +e
          failed=
          for target in $targets; do
            part=''${target%%:*}
            dir="$config/''${target#*:}"
            if [ -d "$staging/old/$part" ]; then
              rm -rf "$dir" && mv "$staging/old/$part" "$dir" || failed=1
            elif [ -e "$staging/old/$part.fresh" ]; then
              rm -rf "$dir" || failed=1
            fi
          done
          if [ -n "$failed" ]; then
            echo "could not roll back everything, the old files are in $staging/old" >&2
            exit 1
          fi
          rm -rf "$staging"
        '
      fi
    }
    trap rollback EXIT

    echo "uploading ${config} to $HA_SSH:$HA_CONFIG_DIR"
    uploaded=1
    tar -C ${config} --dereference --owner=0 --group=0 --mode=u+w -cf - . | remote '
      [ -f "$config/configuration.yaml" ] || { echo "no configuration.yaml in $config" >&2; exit 1; }
      rm -rf "$staging"
      mkdir -p "$staging/new" "$staging/old"
      # -m: the files get the time of the upload instead of the 1970 of the
      # store, home assistant only reads a yaml dashboard again once it is newer
      tar -m -C "$staging/new" -xf -
      for target in $targets; do
        part=''${target%%:*}
        dir="$config/''${target#*:}"
        mkdir -p "$(dirname "$dir")"
        if [ -d "$dir" ]; then mv "$dir" "$staging/old/$part"; else touch "$staging/old/$part.fresh"; fi
        mv "$staging/new/$part" "$dir"
      done
    '

    echo "checking the new configuration"
    warnings=$(check) || { echo "invalid configuration" >&2; exit 1; }
    if new=$(grep -vxF -f <(printf '%s\n' "$baseline") <<<"$warnings" | grep .); then
      printf '%s\n' "$new" >&2
      echo "the new configuration has warnings" >&2
      exit 1
    fi
    uploaded=
    # dashboards and frontend modules are only read when home assistant starts.
    # The new configuration is in place, a failed clean up must not keep it
    # from being reloaded (the next deploy stops at the left over staging)
    restart=$(remote '
      cmp -s "$staging/old/packages/dashboards.yaml" "$config/packages/nix/dashboards.yaml" || echo yes
      rm -rf "$staging"
    ') || echo "could not clean up $staging" >&2

    echo "reloading"
    api services/homeassistant/reload_all -d '{}' >/dev/null
    if [ -n "$restart" ]; then
      echo "the dashboards changed, restart home assistant to load them"
    fi
  '';
}
