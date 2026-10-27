# building blocks for the packages, which get every attribute of this set (and
# nixpkgs' lib and ./entities.nix) as arguments
{ lib, entities }:
let
  inherit (entities) phone weather;
in
rec {
  # maps whose keys home assistant reads in order (variables can refer to the
  # ones before them), written as a list of single-attribute sets since nix
  # always sorts attribute names
  ordered =
    entries:
    assert lib.assertMsg (lib.all (
      entry: lib.length (lib.attrNames entry) == 1
    ) entries) "ordered: every entry needs exactly one attribute";
    {
      _type = "ordered";
      inherit entries;
    };

  # a list of entity ids as a jinja list literal, to use them in templates
  jinjaList = items: "[${lib.concatMapStringsSep ", " (item: "'${item}'") items}]";

  ## triggers

  # any state change of the entity except it going away or coming back, which
  # is what events (buttons, dials) and sensors reporting a problem need
  changed =
    entity_id: extra:
    let
      unavailable = [
        "unavailable"
        "unknown"
      ];
    in
    {
      trigger = "state";
      inherit entity_id;
      not_from = unavailable;
      not_to = unavailable;
    }
    // extra;

  ## conditions

  state = entity_id: state: {
    condition = "state";
    inherit entity_id state;
  };

  notState = entity_id: value: {
    condition = "not";
    conditions = [ (state entity_id value) ];
  };

  template = value_template: {
    condition = "template";
    inherit value_template;
  };

  isHome = state entities.person "home";
  nightModeOff = state entities.nightMode "off";

  ## actions

  # an action on entities, add `data` with `//`
  call = action: entity_id: {
    inherit action;
    target = { inherit entity_id; };
  };

  # push notification to the phone; a new one with the same tag replaces the
  # old one, `actions` are buttons handled in notifications.nix
  notify =
    {
      message,
      tag,
      title ? null,
      actions ? null,
      interruptionLevel ? null,
    }:
    {
      action = phone;
      data = lib.optionalAttrs (title != null) { inherit title; } // {
        inherit message;
        data = {
          inherit tag;
        }
        // lib.optionalAttrs (actions != null) { inherit actions; }
        // lib.optionalAttrs (interruptionLevel != null) {
          push.interruption-level = interruptionLevel;
        };
      };
    };

  clearNotification = tag: {
    action = phone;
    data = {
      message = "clear_notification";
      data = { inherit tag; };
    };
  };

  # runs script.light_preset and waits for it, see lights.nix
  lightPreset = data: {
    action = entities.scripts.lightPreset;
    inherit data;
  };

  # starts a script without waiting for it to finish
  startScript =
    script: variables:
    call "script.turn_on" script
    // lib.optionalAttrs (variables != { }) {
      data.variables = ordered (lib.mapAttrsToList (name: value: { ${name} = value; }) variables);
    };

  # hourly forecast into `fc`, read it with forecastHours
  hourlyForecast = call "weather.get_forecasts" weather // {
    data.type = "hourly";
    response_variable = "fc";
    continue_on_error = true;
  };
  forecastHours =
    hours:
    "{{ (fc['${weather}'].forecast if fc is defined and fc and '${weather}' in fc else [])[:${toString hours}] }}";

  ## helpers

  # input_datetime holding only a time of day
  timeOfDay =
    {
      name,
      icon,
      initial ? null,
    }:
    {
      has_date = false;
      has_time = true;
      inherit name icon;
    }
    // lib.optionalAttrs (initial != null) { inherit initial; };

  ## automations

  # hue tap dial controlling the room light: 1 toggles it (time-of-day preset)
  # and turns all lights off on a long press (Goodnight in the evening), 2 / 3 /
  # 4 pick Bright / Relax / Night, a long 4 turns the room off and the rotary
  # dims (turning it on if it is off). `longPress` maps button_2 / button_3 to
  # extra actions, `before` runs ahead of every press
  dialSwitch =
    {
      id,
      alias,
      description,
      device,
      light,
      goodnight ? startScript entities.scripts.goodnight { },
      before ? [ ],
      longPress ? { },
    }:
    let
      press = button: event: sequence: {
        conditions = [
          (template "{{ trigger.id == '${button}' and event_type in [\"${event}\"] }}")
        ];
        inherit sequence;
      };
      preset =
        preset:
        lightPreset {
          lights = "{{ room_light }}";
          inherit preset;
        };
      turnOff = call "light.turn_off" "{{ room_light }}";
    in
    {
      inherit id alias description;
      triggers = map (button: changed "${device}_${button}" { id = button; }) [
        "button_1"
        "button_2"
        "button_3"
        "button_4"
        "rotary"
      ];
      actions = before ++ [
        {
          choose = [
            (press "button_1" "short_release" [
              {
                "if" = [ (state light "on") ];
                "then" = [ turnOff ];
                "else" = [ (preset "auto") ];
              }
            ])
            (press "button_1" "long_press" [
              {
                "if" = [ (template "{{ now().hour >= 20 or now().hour < 5 }}") ];
                "then" = [ goodnight ];
                "else" = [ (call "light.turn_off" entities.allLights) ];
              }
            ])
            (press "button_2" "short_release" [ (preset "bright") ])
            (press "button_3" "short_release" [ (preset "relax") ])
            (press "button_4" "short_release" [ (preset "night") ])
            (press "button_4" "long_press" [ turnOff ])
            {
              conditions = [
                {
                  condition = "trigger";
                  id = "rotary";
                }
              ];
              sequence = [
                {
                  "if" = [ (state light "off") ];
                  "then" = [
                    {
                      "if" = [ (template "{{ event_type == 'clock_wise' }}") ];
                      "then" = [ (preset "auto") ];
                    }
                  ];
                  "else" = [
                    (
                      call "light.turn_on" "{{ room_light }}"
                      // {
                        data = {
                          brightness_step_pct = "{{ ([([(steps / 4) | round(0, 'ceil') | int, 2] | max), 25] | min) * (1 if event_type == 'clock_wise' else -1) }}";
                          transition = 0.4;
                        };
                      }
                    )
                  ];
                }
              ];
            }
          ]
          ++ lib.mapAttrsToList (button: press button "long_press") longPress;
        }
      ];
      mode = "queued";
      max = 10;
      max_exceeded = "silent";
      variables = ordered [
        { room_light = light; }
        { event_type = "{{ trigger.to_state.attributes.event_type }}"; }
        { steps = "{{ trigger.to_state.attributes.steps | default(0) | int }}"; }
      ];
    };
}
