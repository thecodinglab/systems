# pushes the rendered packages to the home assistant os host over ssh (via the
# "Terminal & SSH" add-on), validates them through the api and reloads; an
# invalid config is rolled back before home assistant ever loads it
{ pkgs, config }:
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

    packages="$HA_CONFIG_DIR/packages/nix"
    staging="$HA_CONFIG_DIR/.nix-deploy"

    token=$(sops -d --extract '["HOME_ASSISTANT_TOKEN"]' ${./secrets.yaml})

    api() {
      curl -fsS -X POST \
        -H @<(printf 'Authorization: Bearer %s\n' "$token") \
        -H 'Content-Type: application/json' \
        "$HA_URL/api/$1" "''${@:2}"
    }

    remote() {
      ssh "$HA_SSH" "set -eu; config='$HA_CONFIG_DIR'; packages='$packages'; staging='$staging'; $1"
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
        remote '
          if [ -d "$staging/old" ]; then
            rm -rf "$packages"
            mv "$staging/old" "$packages"
          elif [ -e "$staging/fresh" ]; then
            rm -rf "$packages"
          fi
          rm -rf "$staging"
        '
      fi
    }
    trap rollback EXIT

    echo "uploading ${config} to $HA_SSH:$packages"
    uploaded=1
    tar -C ${config} --dereference --owner=0 --group=0 --mode=u+w -cf - . | remote '
      [ -f "$config/configuration.yaml" ] || { echo "no configuration.yaml in $config" >&2; exit 1; }
      rm -rf "$staging"
      mkdir -p "$staging/new" "$(dirname "$packages")"
      tar -C "$staging/new" -xf -
      if [ -d "$packages" ]; then mv "$packages" "$staging/old"; else touch "$staging/fresh"; fi
      mv "$staging/new" "$packages"
    '

    echo "checking the new configuration"
    warnings=$(check) || { echo "invalid configuration" >&2; exit 1; }
    if new=$(grep -vxF -f <(printf '%s\n' "$baseline") <<<"$warnings" | grep .); then
      printf '%s\n' "$new" >&2
      echo "the new configuration has warnings" >&2
      exit 1
    fi
    uploaded=
    remote 'rm -rf "$staging"'

    echo "reloading"
    api services/homeassistant/reload_all -d '{}' >/dev/null
  '';
}
