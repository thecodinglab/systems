{
  entities,
  ordered,
  jinjaList,
  state,
  notState,
  nobodyHome,
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
    meteoswiss
    window
    blinds
    blindPresets
    scripts
    ;

  stormProtection = "input_boolean.storm_protection";
  stormLastDetected = "input_datetime.storm_last_detected";

  # gusts at which the blinds go up. They have taken an orange gale warning
  # with forecast gusts near 60 km/h; the station measures in open terrain at
  # 10 m and the model gusts run high (about twice the measured ones on that
  # day), so only gusts above that go up. The helper overrides it
  gustThreshold = "input_number.storm_gust_threshold";
  defaultGustThreshold = 65;

  # the blinds are on the south-west façade, which faces 232° (OpenStreetMap
  # footprint of the building; the north-east side has none). The sun is on
  # it from about 09:40 in December and 12:10 at midsummer until sunset, most
  # strongly in the late afternoon, when it comes in low from the
  # west-south-west. Before that the blinds can be fully open without direct
  # sun, so opening them at sunrise never lets sun in
  facadeAzimuth = 232;
  sunOnBlinds = "binary_sensor.living_room_sun_on_blinds";
  # on while the sun protection has lowered the blinds, so only it raises them
  # again
  sunProtection = "input_boolean.sun_protection";
  # forecast high today from which the sun is kept out; below it the sun is
  # welcome as free heat
  sunTemperature = "input_number.sun_protection_temperature";
  defaultSunTemperature = 24;

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
      description = "Hue tap dial. 1: toggle (time-of-day preset) / long: all lights off (20:00-05:00: Goodnight). 2: Bright. 3: Relax. 4: Night / long: room off. Rotary: dim (turns on if off). Long 2: blinds Open. Long 3: blinds Privacy.";
      device = entities.dialSwitches.livingRoom;
      light = entities.lights.livingRoom;
      longPress = {
        button_2 = [ (startScript scripts.blindPreset { preset = "open"; }) ];
        button_3 = [ (startScript scripts.blindPreset { preset = "privacy"; }) ];
      };
    })
    {
      id = "1792413858768";
      alias = "Living Room: Close Blinds at Dusk";
      description = "Fully closes all four blinds (blades shut) once it gets dark outside, using the Closed preset, which also re-syncs position and tilt with a full run. Catches up after a restart during the evening (never after midnight, so the motors don't run at night). Paused while storm protection is active.";
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
            {% set blinds = ${jinjaList blinds.all} %}
            {{ (blinds | map('state_attr', 'current_position') | map('int', 0) | select('gt', 0) | list
                + blinds | map('state_attr', 'current_tilt_position') | map('int', 0) | select('gt', 0) | list)
               | count > 0 }}''
          // {
            alias = "Not fully closed yet (position or blade tilt above 0)";
          }
        )
      ];
      actions = [
        {
          action = scripts.blindPreset;
          data.preset = "closed";
        }
      ];
      mode = "single";
    }
    {
      id = "1792500000001";
      alias = "Living Room: Blinds to Privacy in the Morning";
      description = "Counterpart to the dusk automation: once the sun is up, but not before \"Blinds Open After\", sets the blinds to the Privacy preset (top pair open, bottom pair down with the blades at 35 %). Catches up after a restart in the morning. Paused while storm protection is active (the blinds are up then anyway).";
      triggers = [
        {
          trigger = "numeric_state";
          entity_id = "sun.sun";
          attribute = "elevation";
          above = 0;
        }
        {
          trigger = "time";
          at = "input_datetime.blinds_open_after";
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
          after = "input_datetime.blinds_open_after";
          before = "12:00:00";
        }
        (state stormProtection "off")
        (
          template ''
            {{ ${jinjaList blinds.top}
               | map('state_attr', 'current_position') | map('int', 100) | select('lt', 100) | list | count > 0 }}''
          // {
            alias = "Still in the night layout (a top blind is not fully open)";
          }
        )
      ];
      actions = [
        {
          action = scripts.blindPreset;
          data.preset = "privacy";
        }
      ];
      mode = "single";
    }
    {
      id = "1792500000017";
      alias = "Living Room: Sun Protection";
      description = "On warm days (MeteoSwiss forecast high today at or above \"Sun Protection From\") lowers all blinds to Shade (blades at 50 %) once the sun shines on the south-west façade (Sun on Blinds: sun within 80° of the façade's 232°, at least 5° up and the station's radiation says it is sunny, for 10 minutes), and sets them back to Privacy when it has been off the façade or behind clouds for 30 minutes. Checks again every 15 minutes while the sun is on the façade. Only lowers blinds that are in a day layout (top pair fully up) and only raises them if they are still in Shade, so anything set by hand stays; late in the evening (sun below 8°) it leaves them for the dusk automation. Paused while storm protection is on; resumes when it ends. In the cool season it never runs, so the sun can warm the room.";
      triggers = [
        {
          trigger = "state";
          entity_id = sunOnBlinds;
          to = [
            "on"
            "off"
          ];
        }
        {
          trigger = "state";
          entity_id = stormProtection;
          from = "on";
          to = "off";
        }
        # tries again while the sun is on the façade, e.g. once the forecast
        # answers or the day turns out warmer
        {
          trigger = "time_pattern";
          minutes = "/15";
        }
      ];
      conditions = [ (state stormProtection "off") ];
      actions = [
        {
          choose = [
            {
              alias = "Sun on the façade on a warm day";
              conditions = [
                (state sunOnBlinds "on")
                (state sunProtection "off")
                (
                  template ''
                    {{ ${jinjaList blinds.top}
                       | map('state_attr', 'current_position') | map('int', 0) | select('eq', 100) | list | count == 2 }}''
                  // {
                    alias = "In a day layout (top pair fully up)";
                  }
                )
              ];
              sequence = [
                (
                  call "weather.get_forecasts" weather
                  // {
                    data.type = "daily";
                    response_variable = "daily";
                    continue_on_error = true;
                  }
                )
                {
                  variables = ordered [
                    {
                      t_max = ''
                        {%- set t_now = state_attr('${weather}', 'temperature') | float(0) -%}
                        {%- set today = daily['${weather}'].forecast[0] if daily is defined and daily and '${weather}' in daily and daily['${weather}'].forecast else {} -%}
                        {{ [today.temperature | default(t_now) | float(t_now), t_now] | max }}'';
                    }
                    { limit = "{{ states('${sunTemperature}') | float(${toString defaultSunTemperature}) }}"; }
                  ];
                }
                (template "{{ t_max >= limit }}" // { alias = "Warm enough to keep the sun out"; })
                (call "input_boolean.turn_on" sunProtection)
                {
                  action = scripts.blindPreset;
                  data.preset = "shade";
                }
              ];
            }
            {
              alias = "Sun gone (or storm protection over) after shading";
              conditions = [
                (state sunOnBlinds "off")
                (state sunProtection "on")
              ];
              sequence = [
                (call "input_boolean.turn_off" sunProtection)
                (
                  template ''
                    {{ state_attr('sun.sun', 'elevation') | float(0) > 8
                       and ${jinjaList blinds.all} | map('state_attr', 'current_position') | map('int', -1) | select('eq', ${toString blindPresets.shade.top.position}) | list | count == 4
                       and ${jinjaList blinds.all} | map('state_attr', 'current_tilt_position') | map('int', -1) | select('eq', ${toString blindPresets.shade.top.tilt}) | list | count == 4 }}''
                  // {
                    alias = "Still in Shade and not yet evening";
                  }
                )
                {
                  action = scripts.blindPreset;
                  data.preset = "privacy";
                }
              ];
            }
          ];
        }
      ];
      mode = "queued";
      max = 3;
    }
    {
      id = "1792500000004";
      alias = "Living Room: Storm Protection";
      description = "Raises all four external venetian blinds and closes the window (unless it is being aired, which closes it itself) when the nearest MeteoSwiss station measures gusts at or above \"Storm Gust Threshold\" (last 10 minutes) or the forecast has them, or thunder or hail, for the hour in progress (and the next one once it starts within 30 minutes), or when an official MeteoSwiss red wind warning or orange or higher thunderstorm warning is in force for the home location. Lower wind warnings are left to the gusts, the blinds take an orange gale. While Storm Protection is on, the blind presets and the dusk/morning and sun protection automations leave the blinds alone. It turns off again after 45 calm minutes; the dusk automation then closes all blinds if it is evening. Below 0 °C the blinds may be frozen to the sill, so it asks instead of moving them.";
      triggers = [
        {
          trigger = "state";
          entity_id = [
            weather
            meteoswiss.gust
            meteoswiss.windWarning
            meteoswiss.thunderstormWarning
          ];
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
            { gust_now = "{{ states('${meteoswiss.gust}') | float(0) }}"; }
            { upcoming = forecastHours 2; }
            {
              warnings = ''
                {%- set ns = namespace(r=[]) -%}
                {%- if is_state('${meteoswiss.windWarning}', 'on') and state_attr('${meteoswiss.windWarning}', 'level') | int(0) >= 4 -%}
                  {%- set ns.r = ns.r + [level_names[state_attr('${meteoswiss.windWarning}', 'level') | int(0)] ~ ' wind warning'] -%}
                {%- endif -%}
                {%- if is_state('${meteoswiss.thunderstormWarning}', 'on') and state_attr('${meteoswiss.thunderstormWarning}', 'level') | int(0) >= 3 -%}
                  {%- set ns.r = ns.r + [level_names[state_attr('${meteoswiss.thunderstormWarning}', 'level') | int(0)] ~ ' thunderstorm warning'] -%}
                {%- endif -%}
                {{ ns.r }}'';
            }
            {
              reasons = ''
                {%- set ns = namespace(r=warnings) -%} {%- if weather_now in storm_conditions %}{% set ns.r = ns.r + [weather_now | replace('-', ' ') ~ ' now'] %}{% endif -%} {%- if gust_now >= threshold %}{% set ns.r = ns.r + ['gusts ' ~ gust_now | round(0) | int ~ ' km/h'] %}{% endif -%} {%- for f in upcoming if as_datetime(f.datetime) < now() + timedelta(minutes=30) -%}
                  {%- set at = as_local(as_datetime(f.datetime)).strftime('%H:%M') -%}
                  {%- if f.condition in storm_conditions %}{% set ns.r = ns.r + [f.condition | replace('-', ' ') ~ ' at ' ~ at] %}{% endif -%}
                  {%- if (f.wind_gust_speed | default(0) | float(0)) >= threshold %}{% set ns.r = ns.r + ['gusts ' ~ f.wind_gust_speed | round(0) | int ~ ' km/h at ' ~ at] %}{% endif -%}
                {%- endfor -%} {{ ns.r | unique | list }}'';
            }
            { storm = "{{ reasons | count > 0 }}"; }
            {
              lowered = "{{ blinds | select('is_state_attr', 'current_position', 100) | list | count < blinds | count }}";
            }
            { freezing = "{{ state_attr('${weather}', 'temperature') | float(10) < 0 }}"; }
          ];
        }
        {
          variables = ordered [
            {
              data_ok = ''
                {{ has_value('${meteoswiss.gust}') and upcoming | count > 0
                   and has_value('${meteoswiss.windWarning}')
                   and has_value('${meteoswiss.thunderstormWarning}') }}'';
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
                # the blinds go up, so the sun protection starts over once the
                # storm is over
                (call "input_boolean.turn_off" sunProtection)
                {
                  # not while airing, which closes it after 5-10 minutes
                  "if" = [ (notState scripts.airing "on") ];
                  "then" = [
                    {
                      alias = "Close the window with a full run, whatever position HA assumes";
                      sequence = fullRun "close" window;
                    }
                  ];
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
                          action = "BLINDS_RAISE";
                          title = "Raise the blinds";
                        }
                      ];
                    })
                  ];
                  "else" = [
                    (call "script.turn_off" scripts.blindPreset)
                    {
                      alias = "Raise all blinds with a full run (the top limit switch stops them)";
                      sequence = fullRun "open" "{{ blinds }}";
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
                      any_up = "{{ blinds | map('state_attr', 'current_position') | map('int', 0) | select('gt', 0) | list | count > 0 }}";
                    }
                  ];
                }
                (notify {
                  title = "Storm over";
                  message = "Storm protection has ended. {% if evening %}The blinds close for the night. {% elif any_up %}The blinds are still up.{% endif %}";
                  tag = "storm-protection";
                  actions = "{{ [] if evening else [{'action': 'BLINDS_PRIVACY', 'title': 'Blinds to Privacy'}] }}";
                })
              ];
            }
          ];
        }
      ];
      variables = ordered [
        { blinds = blinds.all; }
        {
          storm_conditions = [
            "lightning"
            "lightning-rainy"
            "hail"
            "exceptional"
          ];
        }
        { threshold = "{{ states('${gustThreshold}') | float(${toString defaultGustThreshold}) }}"; }
        {
          level_names = [
            "no"
            "green"
            "yellow"
            "orange"
            "red"
          ];
        }
      ];
      mode = "single";
      max_exceeded = "silent";
    }
    {
      id = "1792500000005";
      alias = "Living Room: Window Rain Guard";
      description = "While the living room window is open (and not being aired, which closes it itself) and it rains (or MeteoSwiss expects rain in the next hour): nobody home -> close it right away; anyone home -> ask me, and close it after 10 minutes without an answer. \"Keep open\" silences the question for 2 hours.";
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
      conditions = [
        (notState window "closed")
        # "Air now" opened it on purpose and closes it itself
        (notState scripts.airing "on")
      ];
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
          "if" = [ nobodyHome ];
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
  # the three Ökensand bulbs as one lamp, the bulbs themselves are hidden in the
  # entity registry
  template = [
    {
      binary_sensor = [
        {
          name = "Living Room Sun on Blinds";
          unique_id = "living_room_sun_on_blinds";
          icon = "mdi:sun-angle-outline";
          # direct sun on the façade: within 80° of its normal (more grazing
          # adds hardly any heat), above the buildings opposite, and sunny by
          # the station's global radiation (at least 55 % of a rough clear sky
          # value for the sun's height); the condition if there is no reading
          state = ''
            {%- set az = state_attr('sun.sun', 'azimuth') | float(0) -%}
            {%- set el = state_attr('sun.sun', 'elevation') | float(-90) -%}
            {%- set off = ((az - ${toString facadeAzimuth} + 540) % 360) - 180 -%}
            {%- if has_value('${meteoswiss.radiation}') -%}
              {%- set sunny = states('${meteoswiss.radiation}') | float(0) >= [120, 550 * sin(el * pi / 180)] | max -%}
            {%- else -%}
              {%- set sunny = states('${weather}') in ['sunny', 'partlycloudy'] -%}
            {%- endif -%}
            {{ el > 5 and off | abs < 80 and sunny }}'';
          delay_on.minutes = 10;
          delay_off.minutes = 30;
        }
      ];
    }
  ];
  light = [
    {
      platform = "group";
      name = "Living Room Ökensand";
      unique_id = "living_room_okensand";
      entities = entities.okensand.livingRoom.bulbs;
    }
  ];
  input_boolean = {
    sun_protection = {
      icon = "mdi:sun-angle-outline";
      name = "Sun Protection";
    };
    storm_protection = {
      icon = "mdi:weather-windy";
      name = "Storm Protection";
    };
  };
  input_datetime = {
    blinds_open_after = timeOfDay {
      icon = "mdi:blinds-open";
      initial = "07:00:00";
      name = "Blinds Open After";
    };
    storm_last_detected = {
      has_date = true;
      has_time = true;
      icon = "mdi:weather-lightning";
      name = "Storm Last Detected";
    };
  };
  input_number = {
    sun_protection_temperature = {
      icon = "mdi:thermometer-high";
      max = 35.0;
      min = 15.0;
      mode = "box";
      name = "Sun Protection From";
      step = 1.0;
      unit_of_measurement = "°C";
    };
    storm_gust_threshold = {
      icon = "mdi:weather-windy-variant";
      max = 100.0;
      min = 20.0;
      mode = "box";
      name = "Storm Gust Threshold";
      step = 1.0;
      unit_of_measurement = "km/h";
    };
  };
  script = {
    blind_preset = {
      alias = "Blind Preset";
      description = "Apply a living room blind layout (Privacy / Open / Shade / Closed / Night). Layouts ending closed first do a full reset close so the blade angle starts from a known zero; tilt is set only after travel has finished, since a tilt command cancels a running travel. Refuses anything but Open while storm protection is active (turn Storm Protection off to override).";
      icon = "mdi:blinds-horizontal";
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
              title = "Blinds";
              message = "Storm protection is active, so the blinds stay up. Turn off Storm Protection to lower them anyway.";
              tag = "storm-protection-refused";
            })
            { stop = "Storm protection is active"; }
          ];
        }
        {
          variables = ordered [
            { top = blinds.top; }
            { bottom = blinds.bottom; }
            { presets = blindPresets; }
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
    blind_reset = {
      alias = "Blind Reset";
      description = "Fully close the blinds from wherever they are (full travel time plus run-on) so position and blade tilt are re-synced to 0%.";
      icon = "mdi:blinds-horizontal-closed";
      mode = "restart";
      fields = ordered [
        {
          blinds = {
            name = "Blinds";
            default = blinds.all;
            selector.entity = {
              domain = "cover";
              multiple = true;
            };
          };
        }
      ];
      sequence = [
        { variables = ordered [ { targets = "{{ blinds | default(${jinjaList blinds.all}) }}"; } ]; }
      ]
      ++ resetClose "{{ targets }}";
    };
  };
}
