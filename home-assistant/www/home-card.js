// home-feature: a tile card feature for what the native features do poorly.
// It renders inside a native tile, takes every colour, radius, font and
// spacing from the theme and comes in two kinds:
//   presets  a segmented control that runs a script with {lights, preset} or
//            {preset}; the segment whose values match the entities is selected
//   panes    the four living room shutters as a window, tap one for more-info
// Config, see ../dashboards/home/home.nix:
//   { type: custom:home-feature, kind: presets, action: script.light_preset,
//     lights: light.x, probe: light.y, color: --state-light-active-color,
//     options: [{ key, name, icon, match: { brightness_pct, color_temp_kelvin } }] }
//   { type: custom:home-feature, kind: presets, action: script.shutter_preset,
//     color: --state-cover-active-color,
//     options: [{ key, name, icon, match: { <cover>: { position, tilt } } }] }
//   { type: custom:home-feature, kind: panes, rows: [[cover, cover], [cover, cover]] }
// An option without match is never selected, one with perform_action (and
// optional data) runs that instead of the card's action, e.g. the Roborock
// programs.

const css = `
  :host {
    display: block;
    --home-color: var(--feature-color, var(--primary-color));
    --home-radius: var(--feature-border-radius, 12px);
    --home-gap: var(--ha-space-1, 4px);
    --home-space: var(--ha-space-2, 8px);
    --home-height: var(--feature-height, 42px);
    /* the selected segment: the card itself on a light theme, a lifted grey
       like iOS on a dark one, where the card is darker than the track */
    --home-thumb: var(--ha-card-background, var(--card-background-color));
    --home-thumb-shadow: 0 1px 3px
      color-mix(in srgb, var(--primary-text-color) 14%, transparent);
    font-family: var(--ha-font-family-body, var(--primary-font-family, inherit));
    -webkit-tap-highlight-color: transparent;
  }
  :host([dark]) {
    --home-thumb: color-mix(
      in srgb,
      var(--primary-text-color) 24%,
      var(--ha-card-background, var(--card-background-color))
    );
    --home-thumb-shadow: none;
  }
  .track {
    position: relative;
    display: flex;
    gap: var(--home-gap);
    height: var(--home-height);
    padding: var(--home-gap);
    box-sizing: border-box;
    border-radius: var(--home-radius);
    container-type: inline-size;
  }
  .track::before, .pane::before {
    content: "";
    position: absolute;
    inset: 0;
    border-radius: inherit;
    background: var(--disabled-color);
    opacity: 0.2;
    pointer-events: none;
  }
  button {
    all: unset;
    box-sizing: border-box;
    cursor: pointer;
    position: relative;
  }
  button:focus-visible {
    outline: 2px solid var(--home-color);
    outline-offset: 1px;
  }
  .segment {
    flex: 1 1 0;
    min-width: 0;
    display: flex;
    align-items: center;
    justify-content: center;
    gap: calc(var(--home-space) * 0.75);
    border-radius: calc(var(--home-radius) - var(--home-gap));
    color: var(--primary-text-color);
    font-size: var(--ha-font-size-m, 14px);
    font-weight: var(--ha-font-weight-medium, 500);
    transition: background-color 180ms ease-in-out, box-shadow 180ms ease-in-out;
  }
  .segment ha-icon {
    --mdc-icon-size: 18px;
    color: var(--secondary-text-color);
    flex: none;
  }
  .segment span {
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
  }
  .segment:hover {
    background: color-mix(in srgb, var(--primary-text-color) 5%, transparent);
  }
  .segment:active {
    background: color-mix(in srgb, var(--primary-text-color) 10%, transparent);
  }
  .segment[aria-pressed="true"] {
    background: var(--home-thumb);
    box-shadow: var(--home-thumb-shadow);
  }
  .segment[aria-pressed="true"] ha-icon {
    color: var(--home-color);
  }
  /* buttons without a selection (programs) take the room their name needs */
  .track.actions .segment {
    flex: 1 1 auto;
    padding: 0 var(--home-gap);
  }
  @container (max-width: 330px) {
    .segment ha-icon { display: none; }
  }

  .panes {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: var(--home-space);
  }
  .pane {
    position: relative;
    height: calc(var(--home-height) * 4 / 3);
    border-radius: var(--home-radius);
    overflow: hidden;
    isolation: isolate;
  }
  .glass {
    position: absolute;
    inset: 0;
    background: var(--home-color);
    opacity: 0.14;
  }
  /* one slat per --home-space, the blade fills --blade of it: all of it
     when the blades are shut, a sliver when they are open */
  .curtain {
    position: absolute;
    left: 0;
    right: 0;
    top: 0;
    transition: height 300ms ease-in-out;
    --slat: color-mix(in srgb, var(--secondary-text-color) 45%, transparent);
    background: repeating-linear-gradient(
      to bottom,
      var(--slat) 0 calc(var(--home-space) * var(--blade)),
      transparent calc(var(--home-space) * var(--blade)) var(--home-space)
    );
  }
  .label {
    position: absolute;
    left: var(--home-space);
    bottom: calc(var(--home-space) * 0.75);
    max-width: calc(100% - 2 * var(--home-space));
    box-sizing: border-box;
    padding: 1px var(--home-space);
    border-radius: calc(var(--home-radius) - var(--home-gap));
    background: var(--ha-card-background, var(--card-background-color));
    color: var(--primary-text-color);
    font-size: var(--ha-font-size-s, 12px);
    font-weight: var(--ha-font-weight-medium, 500);
    line-height: var(--ha-line-height-normal, 1.5);
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
  }
  .label small {
    font-size: inherit;
    font-weight: var(--ha-font-weight-normal, 400);
    color: var(--secondary-text-color);
  }
`;

const close = (a, b, slack) => a != null && b != null && Math.abs(a - b) <= slack;

class HomeFeature extends HTMLElement {
  static getStubConfig() {
    return { kind: "presets", options: [] };
  }

  setConfig(config) {
    if (!config || !["presets", "panes"].includes(config.kind)) {
      throw new Error("home-feature: kind must be presets or panes");
    }
    this._config = config;
    this._key = undefined;
    this._render();
  }

  set hass(hass) {
    this._hass = hass;
    this._render();
  }

  // the tile passes these, nothing here needs them
  set context(_) {}
  set stateObj(_) {}

  getCardSize() {
    return this._config?.kind === "panes" ? 3 : 1;
  }

  _entities() {
    const c = this._config;
    if (c.kind === "panes") return c.rows.flat();
    if (c.lights) return [c.probe || c.lights];
    return [...new Set(c.options.flatMap((o) => Object.keys(o.match || {})))];
  }

  _render() {
    if (!this._config || !this._hass) return;
    this.toggleAttribute("dark", Boolean(this._hass.themes?.darkMode));
    // only redraw when an entity this shows has changed
    const key = this._entities()
      .map((e) => this._hass.states[e])
      .map((s) => s && `${s.state}${JSON.stringify(s.attributes)}`)
      .join("|");
    if (key === this._key) return;
    this._key = key;

    if (!this.shadowRoot) this.attachShadow({ mode: "open" });
    const color = this._config.color ? `var(${this._config.color})` : "";
    this.shadowRoot.innerHTML = `<style>${css}${
      color ? `:host { --home-color: ${color}; }` : ""
    }</style>`;
    this.shadowRoot.append(
      this._config.kind === "panes" ? this._panes() : this._presets(),
    );
  }

  _selected() {
    const { lights, probe } = this._config;
    const options = this._config.options.filter((o) => o.match);
    const states = this._hass.states;
    if (lights) {
      const s = states[probe || lights];
      if (!s || s.state !== "on") return undefined;
      const pct = Math.round(((s.attributes.brightness ?? 0) / 255) * 100);
      const kelvin = s.attributes.color_temp_kelvin;
      return options.find(
        ({ match: m }) =>
          close(pct, m.brightness_pct, 2) &&
          (m.color_temp_kelvin == null || close(kelvin, m.color_temp_kelvin, 60)),
      )?.key;
    }
    return options.find(({ match }) =>
      Object.entries(match).every(([entity, want]) => {
        const a = states[entity]?.attributes ?? {};
        return (
          close(a.current_position, want.position, 3) &&
          close(a.current_tilt_position, want.tilt, 3)
        );
      }),
    )?.key;
  }

  _run(option) {
    const { action, lights } = this._config;
    if (option.perform_action) {
      const [domain, service] = option.perform_action.split(".");
      this._hass.callService(domain, service, option.data ?? {});
      return;
    }
    const [domain, service] = action.split(".");
    const data = { preset: option.key };
    if (lights) data.lights = lights;
    this._hass.callService(domain, service, data);
  }

  _presets() {
    const selected = this._selected();
    const track = document.createElement("div");
    track.className = this._config.options.some((o) => o.match)
      ? "track"
      : "track actions";
    track.setAttribute("role", "group");
    for (const option of this._config.options) {
      const button = document.createElement("button");
      button.className = "segment";
      button.setAttribute("aria-pressed", String(option.key === selected));
      button.title = option.name;
      if (option.icon) {
        const icon = document.createElement("ha-icon");
        icon.icon = option.icon;
        icon.setAttribute("icon", option.icon);
        button.append(icon);
      }
      const name = document.createElement("span");
      name.textContent = option.name;
      button.append(name);
      button.addEventListener("click", (event) => {
        event.stopPropagation();
        this._run(option);
      });
      track.append(button);
    }
    return track;
  }

  _panes() {
    const grid = document.createElement("div");
    grid.className = "panes";
    for (const entity of this._config.rows.flat()) {
      const s = this._hass.states[entity];
      const a = s?.attributes ?? {};
      const position = a.current_position ?? (s?.state === "closed" ? 0 : 100);
      const tilt = a.current_tilt_position;
      // a shut blade fills its slat, an open one is a sliver
      const blade = tilt == null ? 1 : 1 - (tilt / 100) * 0.7;

      const pane = document.createElement("button");
      pane.className = "pane";
      pane.title = s?.attributes.friendly_name ?? entity;
      const glass = document.createElement("div");
      glass.className = "glass";
      const curtain = document.createElement("div");
      curtain.className = "curtain";
      curtain.style.height = `${100 - position}%`;
      curtain.style.setProperty("--blade", blade.toFixed(2));
      const label = document.createElement("div");
      label.className = "label";
      label.textContent =
        !s || s.state === "unavailable"
          ? "Unavailable"
          : position >= 100
            ? "Open"
            : position <= 0
              ? "Closed"
              : `${position} %`;
      if (s && position < 100 && tilt != null) {
        const small = document.createElement("small");
        small.textContent = ` · blades ${tilt} %`;
        label.append(small);
      }
      pane.append(glass, curtain, label);
      pane.addEventListener("click", (event) => {
        event.stopPropagation();
        this.dispatchEvent(
          new CustomEvent("hass-more-info", {
            detail: { entityId: entity },
            bubbles: true,
            composed: true,
          }),
        );
      });
      grid.append(pane);
    }
    return grid;
  }
}

if (!customElements.get("home-feature")) {
  customElements.define("home-feature", HomeFeature);
  window.customCardFeatures = window.customCardFeatures || [];
  window.customCardFeatures.push({
    type: "home-feature",
    name: "Presets and shutter panes",
    supported: () => true,
  });
}
