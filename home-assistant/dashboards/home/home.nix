# the home view as native cards, plus custom:home-feature (../../www/home-card.js)
# as a tile feature for the light and shutter presets and the shutter panes
{
  entities,
  navigate,
  lib,
  ...
}:
let
  inherit (import ./cards.nix)
    section
    heading
    markdown
    tile
    half
    full
    onTap
    performAction
    stateIs
    ;
  inherit (entities) lights scripts shutters;

  # an entity badge for a heading
  badge =
    entity: extra:
    {
      type = "entity";
      inherit entity;
    }
    // extra;

  climate = room: [
    (badge "sensor.${room}_climate_temperature" { })
    (badge "sensor.${room}_climate_humidity" { })
  ];

  room =
    icon: title: badges:
    heading icon title // { inherit badges; };

  navigateTo = view: {
    action = "navigate";
    navigation_path = navigate view;
  };

  presetIcons = {
    bright = "mdi:white-balance-sunny";
    relax = "mdi:sofa-outline";
    cozy = "mdi:candle";
    night = "mdi:weather-night";
  };

  # a light group with its brightness and the presets of script.light_preset
  # as a segmented control, the selected one is the preset whose values the
  # probe light has. The same tile whether the lights are on or off, so
  # nothing moves when they are switched
  lightTile =
    {
      entity,
      presets,
      table ? entities.lightPresets.generic,
      probe ? entity,
    }:
    let
      segments = {
        type = "custom:home-feature";
        kind = "presets";
        action = scripts.lightPreset;
        lights = entity;
        inherit probe;
        color = "--state-light-active-color";
        options = map (key: {
          inherit key;
          name = lib.toUpper (lib.substring 0 1 key) + lib.substring 1 (-1) key;
          icon = presetIcons.${key};
          match = { inherit (table.${key}) brightness_pct color_temp_kelvin; };
        }) presets;
      };
    in
    full {
      inherit entity;
      name = "Lights";
      features = [
        { type = "light-brightness"; }
        segments
      ];
    };

  shutterOptions = [
    {
      key = "open";
      name = "Open";
      icon = "mdi:window-shutter-open";
    }
    {
      key = "shade";
      name = "Shade";
      icon = "mdi:sun-angle-outline";
    }
    {
      key = "privacy";
      name = "Privacy";
      icon = "mdi:eye-off-outline";
    }
    {
      key = "closed";
      name = "Closed";
      icon = "mdi:window-shutter";
    }
  ];

  # the four shutters as one tile: the panes (tap one for its controls) and
  # the layouts. The icon lights up while a layout is applied, the name leads
  # to the shutters view like the subheading above (storm guard is its badge)
  shutterTile = full (
    {
      entity = scripts.shutterPreset;
      name = "Shutters";
      icon = "mdi:window-shutter";
      hide_state = true;
      grid_options = {
        columns = 12;
        rows = 4;
      };
      features = [
        {
          type = "custom:home-feature";
          kind = "panes";
          color = "--state-cover-active-color";
          rows = [
            shutters.top
            shutters.bottom
          ];
        }
        {
          type = "custom:home-feature";
          kind = "presets";
          action = scripts.shutterPreset;
          color = "--state-cover-active-color";
          options = map (
            option:
            let
              layout = entities.shutterPresets.${option.key};
            in
            option
            // {
              match =
                lib.genAttrs shutters.top (_: layout.top) // lib.genAttrs shutters.bottom (_: layout.bottom);
            }
          ) shutterOptions;
        }
      ];
    }
    // onTap (navigateTo "shutters")
  );

  # a small heading that leads to another view, the chevron shows it does
  subheading =
    icon: title: view: badges:
    heading icon title
    // {
      heading_style = "subtitle";
      tap_action = navigateTo view;
      inherit badges;
    };

  toggleTile =
    entity: name: icon:
    half (
      {
        inherit entity name icon;
      }
      // onTap { action = "toggle"; }
    );

  runTile =
    entity: name: icon: action:
    half (
      {
        inherit entity name icon;
        hide_state = true;
      }
      // onTap action
    );

  batteries = [
    "kitchen_dial_switch"
    "living_room_dial_switch"
    "bedroom_dial_switch"
    "kitchen_climate"
    "bedroom_climate"
    "bathroom_climate"
  ];

  lowBattery =
    device:
    let
      entity = "sensor.${device}_battery";
    in
    {
      type = "entity";
      inherit entity;
      show_name = true;
      color = "red";
      visibility = [
        {
          condition = "numeric_state";
          inherit entity;
          below = 20;
        }
      ];
    };

  # always the same two sentences, so the page doesn't move when something is
  # switched; which lights are on the tiles show
  greeting = ''
    {%- set h = now().hour -%}
    # {{ 'Good night' if h < 5 else 'Good morning' if h < 12 else 'Good afternoon' if h < 18 else 'Good evening' }}
    {%- set ns = namespace(open=0, wake=''') -%}
    {%- for e in ${builtins.toJSON shutters.all} -%}
      {%- if not is_state(e, 'closed') %}{% set ns.open = ns.open + 1 %}{% endif -%}
    {%- endfor -%}
    {%- if is_state('input_boolean.bedroom_wake_up_light', 'on') and is_state('input_boolean.bedroom_wake_up_skip_next', 'off') -%}
      {%- for d in range(8) if not ns.wake -%}
        {%- set day = now() + timedelta(days=d) -%}
        {%- set name = day.strftime('%A') | lower -%}
        {%- set t = states('input_datetime.bedroom_wake_up_' ~ name ~ '_time')[:5] -%}
        {%- if is_state('input_boolean.bedroom_wake_up_' ~ name, 'on') and (d > 0 or t > now().strftime('%H:%M')) -%}
          {%- set ns.wake = t ~ (' today' if d == 0 else ' tomorrow' if d == 1 else ' on ' ~ day.strftime('%A')) -%}
        {%- endif -%}
      {%- endfor -%}
    {%- endif %}

    {{ 'The shutters are closed.' if ns.open == 0 else 'The shutters are open.' if ns.open == 4 else ns.open ~ ' of 4 shutters are open.' }}
    {{ 'Wake-up light at ' ~ ns.wake ~ '.' if ns.wake else 'The next wake-up light is skipped.' if is_state('input_boolean.bedroom_wake_up_light', 'on') else 'The wake-up light is off.' }}
  '';

  press = button: performAction "button.press" { target.entity_id = button; };

  # the programs as segments without a selection, one tap to start
  vacuumProgram = key: name: icon: perform_action: data: {
    inherit
      key
      name
      icon
      perform_action
      data
      ;
  };
  pressProgram =
    key: name: icon: button:
    vacuumProgram key name icon "button.press" { entity_id = button; };
in
{
  title = "Home";
  path = "home";
  icon = "mdi:home";
  type = "sections";
  max_columns = 3;
  dense_section_placement = true;

  header = {
    layout = "start";
    badges_position = "bottom";
    badges_wrap = "wrap";
    card = markdown greeting;
  };

  # the ones that are always there come first, the alerts after them only
  # show up when something is wrong, so switching things doesn't move the page
  badges = [
    {
      type = "entity";
      entity = lights.livingRoom;
      name = "Turn off all lights";
      show_name = true;
      show_state = false;
      icon = "mdi:lightbulb-group-off";
      # the same grey whatever the living room light does
      color = "disabled";
      tap_action = performAction "light.turn_off" {
        target.floor_id = [
          "downstairs"
          "upstairs"
        ];
      };
    }
    {
      type = "entity";
      entity = entities.weather;
      state_content = [
        "state"
        "temperature"
      ];
    }
    {
      type = "entity";
      entity = "sensor.electricity_maps_co2_intensity";
      name = "Grid CO₂";
      show_name = true;
      tap_action = navigateTo "energy";
    }
    {
      type = "entity";
      entity = "input_boolean.storm_protection";
      show_name = true;
      color = "orange";
      visibility = [ (stateIs "input_boolean.storm_protection" "on") ];
    }
    {
      type = "entity";
      entity = entities.vacuum;
      show_name = true;
      color = "red";
      visibility = [ (stateIs entities.vacuum "error") ];
    }
    {
      type = "entity";
      entity = "sensor.living_room_roborock_dock_dock_error";
      name = "Roborock dock";
      show_name = true;
      color = "red";
      visibility = [
        {
          condition = "state";
          entity = "sensor.living_room_roborock_dock_dock_error";
          state_not = "ok";
        }
      ];
    }
  ]
  ++ map lowBattery batteries;

  # rooms first, then the house. On the tablet the rows pair living room with
  # upstairs (bedroom, bathroom and office) and kitchen and roborock with
  # outside, the first pair ends at about the same height
  sections = [
    (section [
      (room "mdi:sofa-outline" "Living room" [ ])
      (lightTile {
        entity = lights.livingRoom;
        presets = [
          "bright"
          "relax"
          "night"
        ];
      })
      (subheading "mdi:window-shutter" "Window & shutters" "shutters" [
        (badge "input_boolean.storm_protection" {
          icon = "mdi:weather-windy";
          state_content = [
            "name"
            "state"
          ];
          tap_action.action = "toggle";
        })
      ])
      shutterTile
      # opens the window for 5-10 minutes, the icon lights up until it is
      # closed again
      (
        full {
          entity = scripts.airing;
          name = "Air now";
          icon = "mdi:window-open-variant";
          hide_state = true;
        }
        // onTap (performAction "script.turn_on" { target.entity_id = scripts.airing; })
      )
    ])
    (section [
      (room "mdi:bed-outline" "Bedroom" (climate "bedroom"))
      (lightTile {
        entity = lights.bedroom;
        presets = [
          "bright"
          "relax"
          "cozy"
          "night"
        ];
        # the group mixes main and ambiance lights, one main light tells the
        # preset
        table = entities.lightPresets.bedroom.main;
        probe = entities.twilight.left.main;
      })
      (subheading "mdi:weather-sunset-up" "Wake-up" "wake-up" [ ])
      (toggleTile "input_boolean.bedroom_wake_up_light" "Wake-up light" "mdi:weather-sunset-up")
      (toggleTile "input_boolean.bedroom_wake_up_skip_next" "Skip next" "mdi:alarm-off")
      (toggleTile entities.nightMode "Night mode" "mdi:weather-night")
      (runTile scripts.goodnight "Goodnight" "mdi:bed-clock" (
        performAction "script.turn_on" { target.entity_id = scripts.goodnight; }
      ))
      (room "mdi:desk" "Office" [
        (badge entities.officePresence { })
        (badge "sensor.office_desktop_power" { icon = "mdi:desktop-tower-monitor"; })
      ])
      (toggleTile "light.office_lamp" "Lamp" "mdi:desk-lamp")
      (toggleTile "input_boolean.office_light_override" "Manual light" "mdi:lightbulb-auto-outline")
      (
        full {
          entity = "button.office_desktop_wake_on_lan";
          name = "Wake desktop";
          icon = "mdi:power";
          hide_state = true;
        }
        // onTap (press "button.office_desktop_wake_on_lan")
      )
      # a whole grid row, so the bathroom stands apart from the office tiles
      (
        room "mdi:shower-head" "Bathroom" (climate "bathroom")
        // {
          grid_options.rows = 1;
        }
      )
    ])
    (section [
      (room "mdi:countertop-outline" "Kitchen" (climate "kitchen"))
      (lightTile {
        entity = lights.kitchen;
        presets = [
          "bright"
          "relax"
          "night"
        ];
        table = entities.lightPresets.kitchen;
      })
      (room "mdi:robot-vacuum" "Roborock" [
        (badge "sensor.living_room_roborock_battery" { })
      ])
      # always the same tile: the programs start a run, pause and send home are
      # in its more-info (the commands feature leaves a gap while it is docked)
      (full {
        entity = entities.vacuum;
        name = "Roborock";
        features = [
          {
            type = "custom:home-feature";
            kind = "presets";
            color = "--state-vacuum-active-color";
            options = [
              (vacuumProgram "all" "All" "mdi:home-outline" "vacuum.start" { entity_id = entities.vacuum; })
              (pressProgram "common" "Common" "mdi:sofa-outline"
                "button.living_room_roborock_vacuum_common_areas"
              )
              (pressProgram "bedroom" "Bedroom" "mdi:bed-outline" "button.living_room_roborock_vacuum_bedroom")
              (pressProgram "mop" "Mop" "mdi:water-outline" "button.living_room_roborock_vacuum_and_mop")
            ];
          }
        ];
      })
    ])
    (section [
      (room "mdi:weather-partly-cloudy" "Outside" [ ])
      {
        type = "weather-forecast";
        entity = entities.weather;
        show_current = false;
        show_forecast = true;
        forecast_type = "daily";
      }
    ])
  ];
}
