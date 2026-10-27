{
  lib,
  entities,
  ordered,
  changed,
  state,
  template,
  isHome,
  call,
  lightPreset,
  startScript,
  timeOfDay,
  dialSwitch,
  ...
}:
let
  inherit (entities) lights twilight scripts;

  days = [
    "monday"
    "tuesday"
    "wednesday"
    "thursday"
    "friday"
    "saturday"
    "sunday"
  ];

  # one helper per weekday, bedroom_wake_up_<day><suffix>
  perDay =
    suffix: helper:
    lib.genAttrs' days (
      day: lib.nameValuePair "bedroom_wake_up_${day}${suffix}" (helper (lib.toSentenceCase day))
    );

  stopSunrise = call "script.turn_off" scripts.sunrise;

  # waits, and ends the sunrise if the bedroom lights get turned off meanwhile
  waitUnlessOff = minutes: [
    {
      wait_for_trigger = [
        {
          trigger = "state";
          entity_id = lights.bedroom;
          to = "off";
        }
      ];
      timeout = { inherit minutes; };
      continue_on_timeout = true;
    }
    {
      "if" = [ (template "{{ wait.trigger is not none }}") ];
      "then" = [ { stop = "Bedroom lights were turned off"; } ];
    }
  ];

  fadeOff = call "light.turn_off" lights.bedroom // {
    data.transition = 30;
  };
in
{
  automation = [
    (dialSwitch {
      id = "1791906313030";
      alias = "Bedroom: Dial Switch";
      description = "Hue tap dial. 1: toggle (Relax, Night late at night) / long: all lights off (20:00-05:00: Goodnight). 2: Bright. 3: Relax / long: Cozy (candlelight on the back lights). 4: Night / long: room off. Rotary: dim (turns on if off).";
      device = entities.dialSwitches.bedroom;
      light = lights.bedroom;
      goodnight = startScript scripts.goodnight { from_bedroom = true; };
      before = [ stopSunrise ];
      longPress.button_3 = [
        (lightPreset {
          lights = "{{ room_light }}";
          preset = "cozy";
        })
      ];
    })
    {
      id = "1791906313824";
      alias = "Bedroom: Twilight Buttons";
      description = "Button 1: toggle that lamp (main + ambiance, time-of-day preset). Button 2: toggle only that lamp's ambiance light. Long press either: whole bedroom off.";
      triggers =
        lib.concatMap
          (
            side:
            map (button: changed "event.bedroom_twilight_${side}_${button}" { id = "${side}_${button}"; }) [
              "button_1"
              "button_2"
            ]
          )
          [
            "left"
            "right"
          ];
      actions = [
        stopSunrise
        {
          choose = [
            {
              conditions = [ (template "{{ event_type == \"long_press\" }}") ];
              sequence = [ (call "light.turn_off" lights.bedroom) ];
            }
            {
              conditions = [
                (template "{{ event_type == \"short_release\" and trigger.id.endswith(\"_1\") }}")
              ];
              sequence = [
                {
                  "if" = [ (template "{{ is_state(main, \"on\") or is_state(ambiance, \"on\") }}") ];
                  "then" = [
                    (call "light.turn_off" [
                      "{{ main }}"
                      "{{ ambiance }}"
                    ])
                  ];
                  "else" = [
                    (lightPreset {
                      lights = [
                        "{{ main }}"
                        "{{ ambiance }}"
                      ];
                      preset = "auto";
                    })
                  ];
                }
              ];
            }
            {
              conditions = [
                (template "{{ event_type == \"short_release\" and trigger.id.endswith(\"_2\") }}")
              ];
              sequence = [
                {
                  "if" = [ (template "{{ is_state(ambiance, \"on\") }}") ];
                  "then" = [ (call "light.turn_off" "{{ ambiance }}") ];
                  "else" = [
                    (lightPreset {
                      lights = "{{ ambiance }}";
                      preset = "auto";
                    })
                  ];
                }
              ];
            }
          ];
        }
      ];
      mode = "queued";
      max = 5;
      max_exceeded = "silent";
      variables = ordered [
        { side = "{{ trigger.id.split(\"_\")[0] }}"; }
        { button = "{{ trigger.id.split(\"_\")[-1] }}"; }
        { event_type = "{{ trigger.to_state.attributes.event_type }}"; }
        { main = "light.bedroom_twilight_{{ side }}_main"; }
        { ambiance = "light.bedroom_twilight_{{ side }}_ambiance"; }
      ];
    }
    {
      id = "1791906314051";
      alias = "Bedroom: Wake-up Light";
      description = "Starts the 30 min sunrise before the wake-up time configured for that weekday. Only when the master toggle and the day are enabled, you are home, and the bedroom lights are off. Skips one morning when Wake-up Skip Next is on, then resets it.";
      triggers = map (day: {
        trigger = "time";
        at = {
          entity_id = "input_datetime.bedroom_wake_up_${day}_time";
          offset = "-00:30:00";
        };
        id = day;
      }) days;
      conditions = [
        (state "input_boolean.bedroom_wake_up_light" "on")
        (template "{{ trigger.id == (now() + timedelta(minutes=30)).strftime(\"%A\") | lower }}")
        (template "{{ is_state(\"input_boolean.bedroom_wake_up_\" ~ trigger.id, \"on\") }}")
      ];
      actions = [
        {
          "if" = [ (state "input_boolean.bedroom_wake_up_skip_next" "on") ];
          "then" = [
            (call "input_boolean.turn_off" "input_boolean.bedroom_wake_up_skip_next")
            { stop = "Skipped once"; }
          ];
        }
        isHome
        (state lights.bedroom "off")
        (call "script.turn_on" scripts.sunrise)
      ];
      mode = "single";
    }
  ];
  input_boolean = {
    bedroom_wake_up_light = {
      icon = "mdi:weather-sunset-up";
      name = "Wake-up Light";
    };
    bedroom_wake_up_skip_next = {
      icon = "mdi:alarm-off";
      name = "Bedroom Wake-up Skip Next";
    };
  }
  // perDay "" (day: {
    icon = "mdi:calendar-check";
    name = "Wake-up ${day}";
  });
  input_datetime = perDay "_time" (
    day:
    timeOfDay {
      icon = "mdi:alarm";
      name = "Wake-up ${day} Time";
    }
  );
  script = {
    bedroom_sunrise = {
      alias = "Bedroom: Sunrise";
      description = "30 min sunrise: the back lights glow deep red-orange on the wall, turn amber and then warm white over 15 min, then the downlights join and everything ends warm-bright (3500 K). Stops if the bedroom lights get turned off. Afterwards the bedroom fades off once you are up (office occupied or a downstairs dial pressed), or after 90 min at the latest. Any bedroom button stops the script, so a light you pick by hand stays on.";
      icon = "mdi:weather-sunset-up";
      mode = "restart";
      sequence = [
        {
          variables = ordered [
            { ambiance = twilight.ambiance; }
            { main = twilight.main; }
          ];
        }
        (
          call "light.turn_on" "{{ ambiance }}"
          // {
            alias = "Dawn on the wall, deep red-orange back light like the sun below the horizon";
            data = {
              brightness_pct = 1;
              xy_color = [
                0.64
                0.35
              ];
              effect = "off";
            };
          }
        )
        { delay.seconds = 2; }
        (
          call "light.turn_on" "{{ ambiance }}"
          // {
            data = {
              brightness_pct = 35;
              xy_color = [
                0.56
                0.405
              ];
              transition = 600;
            };
          }
        )
      ]
      ++ waitUnlessOff 10
      ++ [
        (
          call "light.turn_on" "{{ ambiance }}"
          // {
            alias = "Amber turns into warm white";
            data = {
              brightness_pct = 70;
              color_temp_kelvin = 2700;
              transition = 300;
            };
          }
        )
      ]
      ++ waitUnlessOff 5
      ++ [
        (
          call "light.turn_on" "{{ main }}"
          // {
            alias = "Downlights join, everything ends warm-bright rather than cold daylight";
            data = {
              brightness_pct = 1;
              color_temp_kelvin = 2200;
              effect = "off";
            };
          }
        )
        { delay.seconds = 2; }
        (
          call "light.turn_on" "{{ main }}"
          // {
            data = {
              brightness_pct = 100;
              color_temp_kelvin = 3500;
              transition = 900;
            };
          }
        )
        (
          call "light.turn_on" "{{ ambiance }}"
          // {
            data = {
              brightness_pct = 85;
              color_temp_kelvin = 3000;
              transition = 900;
            };
          }
        )
      ]
      ++ waitUnlessOff 15
      ++ [
        {
          "if" = [ (state entities.officePresence "on") ];
          "then" = [
            fadeOff
            { stop = "Already up and in the office"; }
          ];
        }
        {
          wait_for_trigger = [
            {
              trigger = "state";
              entity_id = lights.bedroom;
              to = "off";
              id = "lights_off";
            }
            {
              trigger = "state";
              entity_id = entities.officePresence;
              to = "on";
            }
            # any downstairs dial button
            (changed (lib.concatMap
              (device: map (button: "${device}_button_${toString button}") (lib.range 1 4))
              [
                entities.dialSwitches.kitchen
                entities.dialSwitches.livingRoom
              ]
            ) { })
          ];
          timeout.minutes = 90;
          continue_on_timeout = true;
        }
        {
          "if" = [
            (template "{{ wait.trigger is none or wait.trigger.id != 'lights_off' }}")
            (state lights.bedroom "on")
          ];
          "then" = [ fadeOff ];
        }
      ];
    };
  };
}
