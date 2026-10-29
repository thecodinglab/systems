{
  entities,
  ordered,
  jinjaList,
  state,
  notState,
  template,
  call,
  notify,
  clearNotification,
  startScript,
  hourlyForecast,
  forecastHours,
  wet,
  timeOfDay,
  dialSwitch,
  ...
}:
let
  inherit (entities)
    weather
    window
    shutters
    shutterPresets
    scripts
    ;

  stormProtection = "input_boolean.storm_protection";
  stormLastDetected = "input_datetime.storm_last_detected";

  # the time based covers only know their position by counting, so this stops
  # them and runs all the way, whatever position home assistant assumes
  fullRun = direction: entity: [
    (call "cover.stop_cover" entity)
    (
      call "cover_time_based.set_known_position" entity
      // {
        data.position = if direction == "open" then 0 else 100;
      }
    )
    (call "cover.${direction}_cover" entity)
  ];

  # closes with the full travel time plus run-on, which re-syncs position and
  # blade tilt to 0
  resetClose = entity: [
    (call "cover_time_based.set_known_position" entity // { data.position = 100; })
    (call "cover_time_based.set_known_tilt_position" entity // { data.tilt_position = 100; })
    (call "cover.close_cover" entity)
  ];

  closeWindow = call "cover.close_cover" window;
  markStorm = call "input_datetime.set_datetime" stormLastDetected // {
    data.timestamp = "{{ now().timestamp() }}";
  };
in
{
  automation = [
    (dialSwitch {
      id = "1791906312429";
      alias = "Living Room: Dial Switch";
      description = "Hue tap dial. 1: toggle (time-of-day preset) / long: all lights off (20:00-05:00: Goodnight). 2: Bright. 3: Relax. 4: Night / long: room off. Rotary: dim (turns on if off). Long 2: shutters Open. Long 3: shutters Privacy.";
      device = entities.dialSwitches.livingRoom;
      light = entities.lights.livingRoom;
      longPress = {
        button_2 = [ (startScript scripts.shutterPreset { preset = "open"; }) ];
        button_3 = [ (startScript scripts.shutterPreset { preset = "privacy"; }) ];
      };
    })
    {
      id = "1792413858768";
      alias = "Living Room: Close Shutters at Dusk";
      description = "Fully closes all four shutters (blades shut) once it gets dark outside, using the Closed preset, which also re-syncs position and tilt with a full run. Catches up after a restart during the evening (never after midnight, so the motors don't run at night). Paused while storm protection is active.";
      triggers = [
        {
          trigger = "numeric_state";
          entity_id = "sun.sun";
          attribute = "elevation";
          below = -4;
        }
        {
          trigger = "homeassistant";
          event = "start";
        }
        {
          trigger = "state";
          entity_id = stormProtection;
          from = "on";
          to = "off";
        }
      ];
      conditions = [
        {
          condition = "numeric_state";
          entity_id = "sun.sun";
          attribute = "elevation";
          below = -4;
        }
        {
          condition = "time";
          after = "12:00:00";
          before = "23:59:59";
        }
        (state stormProtection "off")
        (
          template ''
            {% set shutters = ${jinjaList shutters.all} %}
            {{ (shutters | map('state_attr', 'current_position') | map('int', 0) | select('gt', 0) | list
                + shutters | map('state_attr', 'current_tilt_position') | map('int', 0) | select('gt', 0) | list)
               | count > 0 }}''
          // {
            alias = "Not fully closed yet (position or blade tilt above 0)";
          }
        )
      ];
      actions = [
        {
          action = scripts.shutterPreset;
          data.preset = "closed";
        }
      ];
      mode = "single";
    }
    {
      id = "1792500000001";
      alias = "Living Room: Shutters to Privacy in the Morning";
      description = "Counterpart to the dusk automation: once the sun is up, but not before \"Shutters Open After\", sets the shutters to the Privacy preset (top pair open, bottom pair down with the blades at 35 %). Catches up after a restart in the morning. Paused while storm protection is active (the blinds are up then anyway).";
      triggers = [
        {
          trigger = "numeric_state";
          entity_id = "sun.sun";
          attribute = "elevation";
          above = 0;
        }
        {
          trigger = "time";
          at = "input_datetime.shutters_open_after";
        }
        {
          trigger = "homeassistant";
          event = "start";
        }
      ];
      conditions = [
        {
          condition = "numeric_state";
          entity_id = "sun.sun";
          attribute = "elevation";
          above = 0;
        }
        {
          condition = "time";
          after = "input_datetime.shutters_open_after";
          before = "12:00:00";
        }
        (state stormProtection "off")
        (
          template ''
            {{ ${jinjaList shutters.top}
               | map('state_attr', 'current_position') | map('int', 100) | select('lt', 100) | list | count > 0 }}''
          // {
            alias = "Still in the night layout (a top shutter is not fully open)";
          }
        )
      ];
      actions = [
        {
          action = scripts.shutterPreset;
          data.preset = "privacy";
        }
      ];
      mode = "single";
    }
    {
      id = "1792500000004";
      alias = "Living Room: Storm Protection";
      description = "Raises all four outdoor blinds and closes the window when Met.no reports thunder, hail or storm wind now or within the next 2 hours (mean wind at or above \"Storm Wind Threshold\"; Met.no has no gust data). While Storm Protection is on, the shutter presets and the dusk/morning automations leave the blinds alone. It turns off again after 45 calm minutes; the dusk automation then closes all shutters if it is evening. Below 0 °C the blinds may be frozen to the sill, so it asks instead of moving them.";
      triggers = [
        {
          trigger = "state";
          entity_id = weather;
        }
        {
          trigger = "time_pattern";
          minutes = "/10";
        }
        {
          trigger = "homeassistant";
          event = "start";
        }
      ];
      actions = [
        hourlyForecast
        {
          variables = ordered [
            { weather_now = "{{ states('${weather}') }}"; }
            { wind_now = "{{ state_attr('${weather}', 'wind_speed') | float(0) }}"; }
            { gust_now = "{{ state_attr('${weather}', 'wind_gust_speed') | float(0) }}"; }
            { upcoming = forecastHours 2; }
            {
              reasons = ''
                {%- set ns = namespace(r=[]) -%} {%- if weather_now in storm_conditions %}{% set ns.r = ns.r + [weather_now | replace('-', ' ') ~ ' now'] %}{% endif -%} {%- if wind_now >= threshold %}{% set ns.r = ns.r + ['wind ' ~ wind_now | round(0) | int ~ ' km/h'] %}{% endif -%} {%- if gust_now >= threshold * 1.6 %}{% set ns.r = ns.r + ['gusts ' ~ gust_now | round(0) | int ~ ' km/h'] %}{% endif -%} {%- for f in upcoming -%}
                  {%- set at = as_local(as_datetime(f.datetime)).strftime('%H:%M') -%}
                  {%- if f.condition in storm_conditions %}{% set ns.r = ns.r + [f.condition | replace('-', ' ') ~ ' at ' ~ at] %}{% endif -%}
                  {%- if (f.wind_speed | float(0)) >= threshold %}{% set ns.r = ns.r + ['wind ' ~ f.wind_speed | round(0) | int ~ ' km/h at ' ~ at] %}{% endif -%}
                  {%- if (f.wind_gust_speed | default(0) | float(0)) >= threshold * 1.6 %}{% set ns.r = ns.r + ['gusts ' ~ f.wind_gust_speed | round(0) | int ~ ' km/h at ' ~ at] %}{% endif -%}
                {%- endfor -%} {{ ns.r | unique | list }}'';
            }
            { storm = "{{ reasons | count > 0 }}"; }
            {
              lowered = "{{ shutters | select('is_state_attr', 'current_position', 100) | list | count < shutters | count }}";
            }
            { freezing = "{{ state_attr('${weather}', 'temperature') | float(10) < 0 }}"; }
          ];
        }
        {
          variables = ordered [
            {
              data_ok = ''
                {{ states('${weather}') not in ['unavailable', 'unknown']
                   and state_attr('${weather}', 'wind_speed') is not none }}'';
            }
            {
              manual_off = ''
                {{ states.${stormProtection}.context.user_id is not none
                   and now() - states.${stormProtection}.last_changed < timedelta(hours=3) }}'';
            }
          ];
        }
        {
          choose = [
            {
              alias = "Storm starts";
              conditions = [
                (template "{{ storm and is_state('${stormProtection}', 'off') and not manual_off }}")
              ];
              sequence = [
                markStorm
                (call "input_boolean.turn_on" stormProtection)
                {
                  alias = "Close the window with a full run, whatever position HA assumes";
                  sequence = fullRun "close" window;
                }
                {
                  "if" = [ (template "{{ freezing }}") ];
                  "then" = [
                    (notify {
                      title = "Storm warning";
                      message = "{{ reasons | join(', ') | capitalize }}. It is below 0 °C, so the blinds may be frozen to the sill. Check them before raising.";
                      tag = "storm-protection";
                      interruptionLevel = "time-sensitive";
                      actions = [
                        {
                          action = "SHUTTERS_RAISE";
                          title = "Raise the blinds";
                        }
                      ];
                    })
                  ];
                  "else" = [
                    (call "script.turn_off" scripts.shutterPreset)
                    {
                      alias = "Raise all blinds with a full run (the top limit switch stops them)";
                      sequence = fullRun "open" "{{ shutters }}";
                    }
                    (notify {
                      title = "Storm protection";
                      message = "{{ reasons | join(', ') | capitalize }}. Raising the blinds; they stay up until it has been calm for 45 minutes.";
                      tag = "storm-protection";
                      interruptionLevel = "{{ 'time-sensitive' if lowered else 'active' }}";
                    })
                  ];
                }
              ];
            }
            {
              alias = "Still stormy (or no weather data while protection is on)";
              conditions = [
                (template "{{ storm or (not data_ok and is_state('${stormProtection}', 'on')) }}")
              ];
              sequence = [ markStorm ];
            }
            {
              alias = "Calm for 45 minutes";
              conditions = [
                (state stormProtection "on")
                (template "{{ data_ok }}")
                (template "{{ now().timestamp() - state_attr('${stormLastDetected}', 'timestamp') | float(0) > 2700 }}")
              ];
              sequence = [
                (call "input_boolean.turn_off" stormProtection)
                {
                  variables = ordered [
                    { evening = "{{ state_attr('sun.sun', 'elevation') | float(0) < -4 and now().hour >= 12 }}"; }
                    {
                      any_up = "{{ shutters | map('state_attr', 'current_position') | map('int', 0) | select('gt', 0) | list | count > 0 }}";
                    }
                  ];
                }
                (notify {
                  title = "Storm over";
                  message = "Storm protection has ended. {% if evening %}The shutters close for the night. {% elif any_up %}The blinds are still up.{% endif %}";
                  tag = "storm-protection";
                  actions = "{{ [] if evening else [{'action': 'SHUTTERS_PRIVACY', 'title': 'Shutters to Privacy'}] }}";
                })
              ];
            }
          ];
        }
      ];
      variables = ordered [
        { shutters = shutters.all; }
        {
          storm_conditions = [
            "lightning"
            "lightning-rainy"
            "hail"
            "windy"
            "windy-variant"
            "exceptional"
          ];
        }
        { threshold = "{{ states('input_number.storm_wind_threshold') | float(25) }}"; }
      ];
      mode = "single";
      max_exceeded = "silent";
    }
    {
      id = "1792500000005";
      alias = "Living Room: Window Rain Guard";
      description = "While the living room window is open and it rains (or Met.no expects rain in the next hour): away -> close it right away; home -> ask, and close it after 10 minutes without an answer. \"Keep open\" silences the question for 2 hours.";
      triggers = [
        {
          trigger = "state";
          entity_id = weather;
          to = wet;
        }
        {
          trigger = "time_pattern";
          minutes = "/15";
        }
      ];
      conditions = [ (notState window "closed") ];
      actions = [
        hourlyForecast
        {
          variables = ordered [
            { inherit wet; }
            { next_hour = forecastHours 1; }
            { rain_now = "{{ states('${weather}') in wet }}"; }
            {
              rain_soon = ''
                {{ next_hour | selectattr('condition', 'in', wet) | list | count > 0
                   or ((next_hour | map(attribute='precipitation', default=0) | map('float', 0) | list + [0]) | max) >= 0.3 }}'';
            }
          ];
        }
        (template "{{ rain_now or rain_soon }}")
        {
          "if" = [ (notState entities.person "home") ];
          "then" = [
            closeWindow
            (notify {
              title = "Window";
              message = "{{ 'It is raining' if rain_now else 'Rain is expected' }}, so the living room window has been closed.";
              tag = "window-rain";
            })
          ];
          "else" = [
            (notify {
              title = "Window";
              message = "{{ 'It is raining' if rain_now else 'Rain is expected within the hour' }} and the living room window is open. It closes in 10 minutes unless you keep it open.";
              tag = "window-rain";
              interruptionLevel = "time-sensitive";
              actions = [
                {
                  action = "CLOSE_WINDOW";
                  title = "Close now";
                }
                {
                  action = "KEEP_WINDOW_OPEN";
                  title = "Keep open";
                }
              ];
            })
            {
              wait_for_trigger = [
                {
                  trigger = "event";
                  event_type = "mobile_app_notification_action";
                  event_data.action = "CLOSE_WINDOW";
                }
                {
                  trigger = "event";
                  event_type = "mobile_app_notification_action";
                  event_data.action = "KEEP_WINDOW_OPEN";
                }
                {
                  trigger = "state";
                  entity_id = window;
                  to = "closed";
                }
              ];
              timeout.minutes = 10;
              continue_on_timeout = true;
            }
            {
              "if" = [
                (template "{{ wait.trigger is not none and wait.trigger.event is defined and wait.trigger.event.data.action == 'KEEP_WINDOW_OPEN' }}")
              ];
              "then" = [ { delay.hours = 2; } ];
              "else" = [
                {
                  "if" = [ (notState window "closed") ];
                  "then" = [ closeWindow ];
                }
                (clearNotification "window-rain")
              ];
            }
          ];
        }
      ];
      mode = "single";
      max_exceeded = "silent";
    }
    {
      id = "1792500000006";
      alias = "Living Room: Window Open Reminder";
      description = "Reminds you when the living room window has been open for 45 minutes while it is below 12 °C outside, with a button to close it. Repeats every 45 minutes.";
      triggers = [
        {
          trigger = "state";
          entity_id = window;
          to = "open";
          for.minutes = 45;
        }
        {
          trigger = "time_pattern";
          minutes = "/15";
        }
      ];
      conditions = [
        (state window "open" // { for.minutes = 45; })
        {
          condition = "numeric_state";
          entity_id = weather;
          attribute = "temperature";
          below = 12;
        }
        (template ''
          {{ this.attributes.last_triggered is none
             or now() - this.attributes.last_triggered > timedelta(minutes=44) }}'')
      ];
      actions = [
        (notify {
          title = "Window";
          message = "The living room window has been open for {{ ((now() - states.${window}.last_changed).total_seconds() // 60) | int }} minutes and it is {{ state_attr('${weather}', 'temperature') | round(0) | int }} °C outside.";
          tag = "window-open";
          actions = [
            {
              action = "CLOSE_WINDOW";
              title = "Close it";
            }
          ];
        })
      ];
      mode = "single";
    }
  ];
  input_boolean = {
    storm_protection = {
      icon = "mdi:weather-windy";
      name = "Storm Protection";
    };
  };
  input_datetime = {
    shutters_open_after = timeOfDay {
      icon = "mdi:window-shutter-open";
      initial = "07:00:00";
      name = "Shutters Open After";
    };
    storm_last_detected = {
      has_date = true;
      has_time = true;
      icon = "mdi:weather-lightning";
      name = "Storm Last Detected";
    };
  };
  input_number = {
    storm_wind_threshold = {
      icon = "mdi:weather-windy-variant";
      max = 80.0;
      min = 10.0;
      mode = "box";
      name = "Storm Wind Threshold";
      step = 1.0;
      unit_of_measurement = "km/h";
    };
  };
  script = {
    shutter_preset = {
      alias = "Shutter Preset";
      description = "Apply a living room shutter layout (Privacy / Open / Shade / Closed / Night). Layouts ending closed first do a full reset close so the blade angle starts from a known zero; tilt is set only after travel has finished, since a tilt command cancels a running travel. Refuses anything but Open while storm protection is active (turn Storm Protection off to override).";
      icon = "mdi:window-shutter-settings";
      mode = "restart";
      fields = ordered [
        {
          preset = {
            name = "Preset";
            required = true;
            default = "privacy";
            selector.select.options = [
              "privacy"
              "open"
              "shade"
              "closed"
              "night"
            ];
          };
        }
      ];
      sequence = [
        {
          "if" = [
            (state stormProtection "on")
            (template "{{ (preset | default(\"privacy\")) != \"open\" }}")
          ];
          "then" = [
            (notify {
              title = "Shutters";
              message = "Storm protection is active, so the blinds stay up. Turn off Storm Protection to lower them anyway.";
              tag = "storm-protection-refused";
            })
            { stop = "Storm protection is active"; }
          ];
        }
        {
          variables = ordered [
            { top = shutters.top; }
            { bottom = shutters.bottom; }
            { presets = shutterPresets; }
            { layout = "{{ presets[preset | default('privacy')] }}"; }
          ];
        }
        {
          # both pairs at once: travel, then the blades once they have stopped
          parallel =
            map
              (pair: {
                sequence = [
                  {
                    "if" = [ (template "{{ layout.${pair}.position == 0 }}") ];
                    "then" = resetClose "{{ ${pair} }}";
                    "else" = [
                      (
                        call "cover.set_cover_position" "{{ ${pair} }}"
                        // {
                          data.position = "{{ layout.${pair}.position }}";
                        }
                      )
                    ];
                  }
                  { delay.seconds = 2; }
                  {
                    wait_template = "{{ ${pair} | reject('is_state', ['opening', 'closing']) | list | count == ${pair} | count and ${pair} | map('state_attr', 'current_position') | list | select('eq', layout.${pair}.position) | list | count == ${pair} | count }}";
                    timeout.minutes = 2;
                    continue_on_timeout = false;
                  }
                  { delay.seconds = 3; }
                  (
                    call "cover.set_cover_tilt_position" "{{ ${pair} }}"
                    // {
                      data.tilt_position = "{{ layout.${pair}.tilt }}";
                    }
                  )
                ];
              })
              [
                "top"
                "bottom"
              ];
        }
      ];
    };
    shutter_reset = {
      alias = "Shutter Reset";
      description = "Fully close the shutters from wherever they are (full travel time plus run-on) so position and blade tilt are re-synced to 0%.";
      icon = "mdi:window-shutter-alert";
      mode = "restart";
      fields = ordered [
        {
          shutters = {
            name = "Shutters";
            default = shutters.all;
            selector.entity = {
              domain = "cover";
              multiple = true;
            };
          };
        }
      ];
      sequence = [
        { variables = ordered [ { targets = "{{ shutters | default(${jinjaList shutters.all}) }}"; } ]; }
      ]
      ++ resetClose "{{ targets }}";
    };
  };
}
