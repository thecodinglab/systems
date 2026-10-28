# Home Assistant

Automations, scripts, helpers and dashboards for the Home Assistant OS
instance at `home.florian-walter.ch` (`192.168.128.100`). Every file in
`packages/` is a
[package](https://www.home-assistant.io/docs/configuration/packages/): an
attrset with the same shape as `configuration.yaml`, rendered to
`<name>.yaml` and deployed to `/homeassistant/packages/nix/`. Dashboards and
their cards go to `/homeassistant/dashboards/nix/` and `/homeassistant/www/nix/`
(see [Dashboards](#dashboards)).

```sh
make home-assistant
```

uploads everything over ssh, validates the whole configuration via
the API (rolling the upload back if it is invalid) and reloads all YAML. The
API token is in `secrets.yaml` (sops). `HA_URL`, `HA_SSH` and `HA_CONFIG_DIR`
override the defaults in `deploy.nix`.

Anything defined here is read-only in the UI. Things that only exist in the UI
stay there and are covered by the regular Home Assistant backups: integrations
and devices, area/label/icon assignments (entity registry), the dashboards
that are not in `dashboards/`, HACS.

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

## Dashboards

Every file or directory in `dashboards/` is a YAML mode dashboard, registered
in `packages/dashboards.nix` (with its url and sidebar entry). Its views are
regular Lovelace config, written in Nix like the packages and taking the same
arguments.

The home view of `dashboards/home` (`home.nix`) is native cards in the look of
the theme, plus one custom tile feature, `custom:home-feature` in
`www/home-card.js`. That's a plain web component without a build step, styled
only with the theme's variables. It has two kinds:

- a segmented control for the light presets, the shutter layouts and the
  Roborock programs, which marks the preset the lights or shutters are at
  (using the tables in `entities.nix`)
- the four living room shutters drawn as a window

Nothing on the view appears or disappears when something is switched, so the
page doesn't move; only alerts (storm, Roborock stuck, low batteries) add
badges at the end of the header.

- `www/loader.js` is loaded on every page through `frontend.extra_module_url`.
  Home Assistant serves `/local` with a month long cache, so the loader never
  changes and imports the cards with the hash of the deploy (`www/version`)
  appended.
- Home Assistant only reads `lovelace` dashboards and `frontend` modules when it
  starts. The deploy says when a restart is needed (when
  `packages/dashboards.yaml` changed); changes to a dashboard's views or the
  cards only need a reload of the page.

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
