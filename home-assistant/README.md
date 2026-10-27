# Home Assistant

Automations, scripts and helpers for the Home Assistant OS instance at
`home.florian-walter.ch` (`192.168.128.100`). Every file in `packages/` is a
[package](https://www.home-assistant.io/docs/configuration/packages/): an
attrset with the same shape as `configuration.yaml`, rendered to
`<name>.yaml` and deployed to `/homeassistant/packages/nix/`.

```sh
make home-assistant
```

uploads the rendered packages over ssh, validates the whole configuration via
the API (rolling the upload back if it is invalid) and reloads all YAML. The
API token is in `secrets.yaml` (sops). `HA_URL`, `HA_SSH` and `HA_CONFIG_DIR`
override the defaults in `deploy.nix`.

Anything defined here is read-only in the UI. Things that only exist in the UI
stay there and are covered by the regular Home Assistant backups: integrations
and devices, area/label/icon assignments (entity registry), dashboards, HACS.

## Writing packages

Package files are functions of `{ lib, entities, ... }` plus everything in
`lib.nix`, and take what they use:

- `entities.nix` has the entity ids used in more than one place (the phone,
  room lights, shutters, scripts, ...). Renaming a device in home assistant
  only needs a change there.
- `lib.nix` has the building blocks: conditions (`state`, `template`,
  `isHome`, ...), actions (`call`, `notify`, `lightPreset`, `startScript`,
  ...), `jinjaList` to put a nix list of entity ids into a template and
  `dialSwitch` for a hue tap dial controlling a room.
- Things only repeated within one package stay in that package's `let`.

- Keep `id` on automations: it is the entity's unique id, the entity registry
  (entity id, area, icon) is attached to it.
- Script and helper keys are their entity ids (`script.<key>`,
  `input_boolean.<key>`, ...).
- Nix sorts attribute names, but home assistant evaluates `variables` in order
  (later ones can use earlier ones), so they are written with `ordered`:
  `variables = ordered [ { a = ...; } { b = "{{ a }}"; } ]`. `fields` use it
  too, it sets the order in the UI.
- Home assistant merges packages recursively and silently drops empty maps on
  the way, so options-less selectors are written `boolean = null`; the build
  fails on an empty map where it would be dropped.
- `''` strings are fine for templates; `${` has to be escaped as `''${`.
  Templates can be tried out in the UI under Developer tools → Template.

## Setup

The automations, scripts and helpers were created in the UI before and moved
over once (keeping their entity registry entries). A new host only needs:

1. The official **Terminal & SSH** add-on with the personal key from
   `lib/keys.nix` in `authorized_keys` and the SSH port set to 22 in its
   network settings. `ssh root@192.168.128.100 ls /homeassistant` should work.
2. The packages directory in `configuration.yaml`:

   ```yaml
   homeassistant:
     packages: !include_dir_named packages
   ```
