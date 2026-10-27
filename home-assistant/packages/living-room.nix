{ ordered }:
{
  automation = [
    {
      id = "1791906312429";
      alias = "Living Room: Dial Switch";
      description = "Hue tap dial. 1: toggle (time-of-day preset) / long: all lights off (20:00-05:00: Goodnight). 2: Bright. 3: Relax. 4: Night / long: room off. Rotary: dim (turns on if off). Long 2: shutters Open. Long 3: shutters Privacy.";
      triggers = [
        {
          trigger = "state";
          entity_id = "event.living_room_dial_switch_button_1";
          not_from = [
            "unavailable"
            "unknown"
          ];
          not_to = [
            "unavailable"
            "unknown"
          ];
          id = "button_1";
        }
        {
          trigger = "state";
          entity_id = "event.living_room_dial_switch_button_2";
          not_from = [
            "unavailable"
            "unknown"
          ];
          not_to = [
            "unavailable"
            "unknown"
          ];
          id = "button_2";
        }
        {
          trigger = "state";
          entity_id = "event.living_room_dial_switch_button_3";
          not_from = [
            "unavailable"
            "unknown"
          ];
          not_to = [
            "unavailable"
            "unknown"
          ];
          id = "button_3";
        }
        {
          trigger = "state";
          entity_id = "event.living_room_dial_switch_button_4";
          not_from = [
            "unavailable"
            "unknown"
          ];
          not_to = [
            "unavailable"
            "unknown"
          ];
          id = "button_4";
        }
        {
          trigger = "state";
          entity_id = "event.living_room_dial_switch_rotary";
          not_from = [
            "unavailable"
            "unknown"
          ];
          not_to = [
            "unavailable"
            "unknown"
          ];
          id = "rotary";
        }
      ];
      actions = [
        {
          choose = [
            {
              conditions = [
                {
                  condition = "template";
                  value_template = "{{ trigger.id == 'button_1' and event_type in [\"short_release\"] }}";
                }
              ];
              sequence = [
                {
                  "if" = [
                    {
                      condition = "state";
                      entity_id = "light.living_room_lights";
                      state = "on";
                    }
                  ];
                  "then" = [
                    {
                      action = "light.turn_off";
                      target = {
                        entity_id = "{{ room_light }}";
                      };
                    }
                  ];
                  "else" = [
                    {
                      action = "script.light_preset";
                      data = {
                        lights = "{{ room_light }}";
                        preset = "auto";
                      };
                    }
                  ];
                }
              ];
            }
            {
              conditions = [
                {
                  condition = "template";
                  value_template = "{{ trigger.id == 'button_1' and event_type in [\"long_press\"] }}";
                }
              ];
              sequence = [
                {
                  "if" = [
                    {
                      condition = "template";
                      value_template = "{{ now().hour >= 20 or now().hour < 5 }}";
                    }
                  ];
                  "then" = [
                    {
                      action = "script.turn_on";
                      target = {
                        entity_id = "script.goodnight";
                      };
                    }
                  ];
                  "else" = [
                    {
                      action = "light.turn_off";
                      target = {
                        entity_id = [
                          "light.kitchen_lights"
                          "light.living_room_lights"
                          "light.bedroom_lights"
                          "light.office_lights"
                        ];
                      };
                    }
                  ];
                }
              ];
            }
            {
              conditions = [
                {
                  condition = "template";
                  value_template = "{{ trigger.id == 'button_2' and event_type in [\"short_release\"] }}";
                }
              ];
              sequence = [
                {
                  action = "script.light_preset";
                  data = {
                    lights = "{{ room_light }}";
                    preset = "bright";
                  };
                }
              ];
            }
            {
              conditions = [
                {
                  condition = "template";
                  value_template = "{{ trigger.id == 'button_3' and event_type in [\"short_release\"] }}";
                }
              ];
              sequence = [
                {
                  action = "script.light_preset";
                  data = {
                    lights = "{{ room_light }}";
                    preset = "relax";
                  };
                }
              ];
            }
            {
              conditions = [
                {
                  condition = "template";
                  value_template = "{{ trigger.id == 'button_4' and event_type in [\"short_release\"] }}";
                }
              ];
              sequence = [
                {
                  action = "script.light_preset";
                  data = {
                    lights = "{{ room_light }}";
                    preset = "night";
                  };
                }
              ];
            }
            {
              conditions = [
                {
                  condition = "template";
                  value_template = "{{ trigger.id == 'button_4' and event_type in [\"long_press\"] }}";
                }
              ];
              sequence = [
                {
                  action = "light.turn_off";
                  target = {
                    entity_id = "{{ room_light }}";
                  };
                }
              ];
            }
            {
              conditions = [
                {
                  condition = "trigger";
                  id = "rotary";
                }
              ];
              sequence = [
                {
                  "if" = [
                    {
                      condition = "state";
                      entity_id = "light.living_room_lights";
                      state = "off";
                    }
                  ];
                  "then" = [
                    {
                      "if" = [
                        {
                          condition = "template";
                          value_template = "{{ event_type == 'clock_wise' }}";
                        }
                      ];
                      "then" = [
                        {
                          action = "script.light_preset";
                          data = {
                            lights = "{{ room_light }}";
                            preset = "auto";
                          };
                        }
                      ];
                    }
                  ];
                  "else" = [
                    {
                      action = "light.turn_on";
                      target = {
                        entity_id = "{{ room_light }}";
                      };
                      data = {
                        brightness_step_pct = "{{ ([([(steps / 4) | round(0, 'ceil') | int, 2] | max), 25] | min) * (1 if event_type == 'clock_wise' else -1) }}";
                        transition = 0.4;
                      };
                    }
                  ];
                }
              ];
            }
            {
              conditions = [
                {
                  condition = "template";
                  value_template = "{{ trigger.id == 'button_2' and event_type in [\"long_press\"] }}";
                }
              ];
              sequence = [
                {
                  action = "script.turn_on";
                  target = {
                    entity_id = "script.shutter_preset";
                  };
                  data = {
                    variables = ordered [ { preset = "open"; } ];
                  };
                }
              ];
            }
            {
              conditions = [
                {
                  condition = "template";
                  value_template = "{{ trigger.id == 'button_3' and event_type in [\"long_press\"] }}";
                }
              ];
              sequence = [
                {
                  action = "script.turn_on";
                  target = {
                    entity_id = "script.shutter_preset";
                  };
                  data = {
                    variables = ordered [ { preset = "privacy"; } ];
                  };
                }
              ];
            }
          ];
        }
      ];
      mode = "queued";
      max = 10;
      max_exceeded = "silent";
      variables = ordered [
        { room_light = "light.living_room_lights"; }
        { event_type = "{{ trigger.to_state.attributes.event_type }}"; }
        { steps = "{{ trigger.to_state.attributes.steps | default(0) | int }}"; }
      ];
    }
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
          entity_id = "input_boolean.storm_protection";
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
        {
          condition = "state";
          entity_id = "input_boolean.storm_protection";
          state = "off";
        }
        {
          alias = "Not fully closed yet (position or blade tilt above 0)";
          condition = "template";
          value_template = ''
            {% set shutters = ['cover.living_room_shutter_top_left', 'cover.living_room_shutter_top_right',
                               'cover.living_room_shutter_bottom_left', 'cover.living_room_shutter_bottom_right'] %}
            {{ (shutters | map('state_attr', 'current_position') | map('int', 0) | select('gt', 0) | list
                + shutters | map('state_attr', 'current_tilt_position') | map('int', 0) | select('gt', 0) | list)
               | count > 0 }}'';
        }
      ];
      actions = [
        {
          action = "script.shutter_preset";
          data = {
            preset = "closed";
          };
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
        {
          condition = "state";
          entity_id = "input_boolean.storm_protection";
          state = "off";
        }
        {
          alias = "Still in the night layout (a top shutter is not fully open)";
          condition = "template";
          value_template = ''
            {{ ['cover.living_room_shutter_top_left', 'cover.living_room_shutter_top_right']
               | map('state_attr', 'current_position') | map('int', 100) | select('lt', 100) | list | count > 0 }}'';
        }
      ];
      actions = [
        {
          action = "script.shutter_preset";
          data = {
            preset = "privacy";
          };
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
          entity_id = "weather.forecast_home";
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
        {
          action = "weather.get_forecasts";
          target = {
            entity_id = "weather.forecast_home";
          };
          data = {
            type = "hourly";
          };
          response_variable = "fc";
          continue_on_error = true;
        }
        {
          variables = ordered [
            { weather_now = "{{ states('weather.forecast_home') }}"; }
            { wind_now = "{{ state_attr('weather.forecast_home', 'wind_speed') | float(0) }}"; }
            { gust_now = "{{ state_attr('weather.forecast_home', 'wind_gust_speed') | float(0) }}"; }
            {
              upcoming = "{{ (fc['weather.forecast_home'].forecast if fc is defined and fc and 'weather.forecast_home' in fc else [])[:2] }}";
            }
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
            { freezing = "{{ state_attr('weather.forecast_home', 'temperature') | float(10) < 0 }}"; }
          ];
        }
        {
          variables = ordered [
            {
              data_ok = ''
                {{ states('weather.forecast_home') not in ['unavailable', 'unknown']
                   and state_attr('weather.forecast_home', 'wind_speed') is not none }}'';
            }
            {
              manual_off = ''
                {{ states.input_boolean.storm_protection.context.user_id is not none
                   and now() - states.input_boolean.storm_protection.last_changed < timedelta(hours=3) }}'';
            }
          ];
        }
        {
          choose = [
            {
              alias = "Storm starts";
              conditions = [
                {
                  condition = "template";
                  value_template = "{{ storm and is_state('input_boolean.storm_protection', 'off') and not manual_off }}";
                }
              ];
              sequence = [
                {
                  action = "input_datetime.set_datetime";
                  target = {
                    entity_id = "input_datetime.storm_last_detected";
                  };
                  data = {
                    timestamp = "{{ now().timestamp() }}";
                  };
                }
                {
                  action = "input_boolean.turn_on";
                  target = {
                    entity_id = "input_boolean.storm_protection";
                  };
                }
                {
                  alias = "Close the window with a full run, whatever position HA assumes";
                  sequence = [
                    {
                      action = "cover.stop_cover";
                      target = {
                        entity_id = "cover.living_room_window";
                      };
                    }
                    {
                      action = "cover_time_based.set_known_position";
                      target = {
                        entity_id = "cover.living_room_window";
                      };
                      data = {
                        position = 100;
                      };
                    }
                    {
                      action = "cover.close_cover";
                      target = {
                        entity_id = "cover.living_room_window";
                      };
                    }
                  ];
                }
                {
                  "if" = [
                    {
                      condition = "template";
                      value_template = "{{ freezing }}";
                    }
                  ];
                  "then" = [
                    {
                      action = "notify.mobile_app_florians_iphone_18";
                      data = {
                        title = "Storm warning";
                        message = "{{ reasons | join(', ') | capitalize }}. It is below 0 °C, so the blinds may be frozen to the sill. Check them before raising.";
                        data = {
                          tag = "storm-protection";
                          push = {
                            interruption-level = "time-sensitive";
                          };
                          actions = [
                            {
                              action = "SHUTTERS_RAISE";
                              title = "Raise the blinds";
                            }
                          ];
                        };
                      };
                    }
                  ];
                  "else" = [
                    {
                      action = "script.turn_off";
                      target = {
                        entity_id = "script.shutter_preset";
                      };
                    }
                    {
                      alias = "Raise all blinds with a full run (the top limit switch stops them)";
                      sequence = [
                        {
                          action = "cover.stop_cover";
                          target = {
                            entity_id = "{{ shutters }}";
                          };
                        }
                        {
                          action = "cover_time_based.set_known_position";
                          target = {
                            entity_id = "{{ shutters }}";
                          };
                          data = {
                            position = 0;
                          };
                        }
                        {
                          action = "cover.open_cover";
                          target = {
                            entity_id = "{{ shutters }}";
                          };
                        }
                      ];
                    }
                    {
                      action = "notify.mobile_app_florians_iphone_18";
                      data = {
                        title = "Storm protection";
                        message = "{{ reasons | join(', ') | capitalize }}. Raising the blinds; they stay up until it has been calm for 45 minutes.";
                        data = {
                          tag = "storm-protection";
                          push = {
                            interruption-level = "{{ 'time-sensitive' if lowered else 'active' }}";
                          };
                        };
                      };
                    }
                  ];
                }
              ];
            }
            {
              alias = "Still stormy (or no weather data while protection is on)";
              conditions = [
                {
                  condition = "template";
                  value_template = "{{ storm or (not data_ok and is_state('input_boolean.storm_protection', 'on')) }}";
                }
              ];
              sequence = [
                {
                  action = "input_datetime.set_datetime";
                  target = {
                    entity_id = "input_datetime.storm_last_detected";
                  };
                  data = {
                    timestamp = "{{ now().timestamp() }}";
                  };
                }
              ];
            }
            {
              alias = "Calm for 45 minutes";
              conditions = [
                {
                  condition = "state";
                  entity_id = "input_boolean.storm_protection";
                  state = "on";
                }
                {
                  condition = "template";
                  value_template = "{{ data_ok }}";
                }
                {
                  condition = "template";
                  value_template = "{{ now().timestamp() - state_attr('input_datetime.storm_last_detected', 'timestamp') | float(0) > 2700 }}";
                }
              ];
              sequence = [
                {
                  action = "input_boolean.turn_off";
                  target = {
                    entity_id = "input_boolean.storm_protection";
                  };
                }
                {
                  variables = ordered [
                    { evening = "{{ state_attr('sun.sun', 'elevation') | float(0) < -4 and now().hour >= 12 }}"; }
                    {
                      any_up = "{{ shutters | map('state_attr', 'current_position') | map('int', 0) | select('gt', 0) | list | count > 0 }}";
                    }
                  ];
                }
                {
                  action = "notify.mobile_app_florians_iphone_18";
                  data = {
                    title = "Storm over";
                    message = "Storm protection has ended. {% if evening %}The shutters close for the night. {% elif any_up %}The blinds are still up.{% endif %}";
                    data = {
                      tag = "storm-protection";
                      actions = "{{ [] if evening else [{'action': 'SHUTTERS_PRIVACY', 'title': 'Shutters to Privacy'}] }}";
                    };
                  };
                }
              ];
            }
          ];
        }
      ];
      variables = ordered [
        {
          shutters = [
            "cover.living_room_shutter_top_left"
            "cover.living_room_shutter_top_right"
            "cover.living_room_shutter_bottom_left"
            "cover.living_room_shutter_bottom_right"
          ];
        }
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
          entity_id = "weather.forecast_home";
          to = [
            "rainy"
            "pouring"
            "lightning-rainy"
            "snowy"
            "snowy-rainy"
            "hail"
          ];
        }
        {
          trigger = "time_pattern";
          minutes = "/15";
        }
      ];
      conditions = [
        {
          condition = "not";
          conditions = [
            {
              condition = "state";
              entity_id = "cover.living_room_window";
              state = "closed";
            }
          ];
        }
      ];
      actions = [
        {
          action = "weather.get_forecasts";
          target = {
            entity_id = "weather.forecast_home";
          };
          data = {
            type = "hourly";
          };
          response_variable = "fc";
          continue_on_error = true;
        }
        {
          variables = ordered [
            {
              wet = [
                "rainy"
                "pouring"
                "lightning-rainy"
                "snowy"
                "snowy-rainy"
                "hail"
              ];
            }
            {
              next_hour = "{{ (fc['weather.forecast_home'].forecast if fc is defined and fc and 'weather.forecast_home' in fc else [])[:1] }}";
            }
            { rain_now = "{{ states('weather.forecast_home') in wet }}"; }
            {
              rain_soon = ''
                {{ next_hour | selectattr('condition', 'in', wet) | list | count > 0
                   or ((next_hour | map(attribute='precipitation', default=0) | map('float', 0) | list + [0]) | max) >= 0.3 }}'';
            }
          ];
        }
        {
          condition = "template";
          value_template = "{{ rain_now or rain_soon }}";
        }
        {
          "if" = [
            {
              condition = "not";
              conditions = [
                {
                  condition = "state";
                  entity_id = "person.florian";
                  state = "home";
                }
              ];
            }
          ];
          "then" = [
            {
              action = "cover.close_cover";
              target = {
                entity_id = "cover.living_room_window";
              };
            }
            {
              action = "notify.mobile_app_florians_iphone_18";
              data = {
                title = "Window";
                message = "{{ 'It is raining' if rain_now else 'Rain is expected' }}, so the living room window has been closed.";
                data = {
                  tag = "window-rain";
                };
              };
            }
          ];
          "else" = [
            {
              action = "notify.mobile_app_florians_iphone_18";
              data = {
                title = "Window";
                message = "{{ 'It is raining' if rain_now else 'Rain is expected within the hour' }} and the living room window is open. It closes in 10 minutes unless you keep it open.";
                data = {
                  tag = "window-rain";
                  push = {
                    interruption-level = "time-sensitive";
                  };
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
                };
              };
            }
            {
              wait_for_trigger = [
                {
                  trigger = "event";
                  event_type = "mobile_app_notification_action";
                  event_data = {
                    action = "CLOSE_WINDOW";
                  };
                }
                {
                  trigger = "event";
                  event_type = "mobile_app_notification_action";
                  event_data = {
                    action = "KEEP_WINDOW_OPEN";
                  };
                }
                {
                  trigger = "state";
                  entity_id = "cover.living_room_window";
                  to = "closed";
                }
              ];
              timeout = {
                minutes = 10;
              };
              continue_on_timeout = true;
            }
            {
              "if" = [
                {
                  condition = "template";
                  value_template = "{{ wait.trigger is not none and wait.trigger.event is defined and wait.trigger.event.data.action == 'KEEP_WINDOW_OPEN' }}";
                }
              ];
              "then" = [
                {
                  delay = {
                    hours = 2;
                  };
                }
              ];
              "else" = [
                {
                  "if" = [
                    {
                      condition = "not";
                      conditions = [
                        {
                          condition = "state";
                          entity_id = "cover.living_room_window";
                          state = "closed";
                        }
                      ];
                    }
                  ];
                  "then" = [
                    {
                      action = "cover.close_cover";
                      target = {
                        entity_id = "cover.living_room_window";
                      };
                    }
                  ];
                }
                {
                  action = "notify.mobile_app_florians_iphone_18";
                  data = {
                    message = "clear_notification";
                    data = {
                      tag = "window-rain";
                    };
                  };
                }
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
          entity_id = "cover.living_room_window";
          to = "open";
          for = {
            minutes = 45;
          };
        }
        {
          trigger = "time_pattern";
          minutes = "/15";
        }
      ];
      conditions = [
        {
          condition = "state";
          entity_id = "cover.living_room_window";
          state = "open";
          for = {
            minutes = 45;
          };
        }
        {
          condition = "numeric_state";
          entity_id = "weather.forecast_home";
          attribute = "temperature";
          below = 12;
        }
        {
          condition = "template";
          value_template = ''
            {{ this.attributes.last_triggered is none
               or now() - this.attributes.last_triggered > timedelta(minutes=44) }}'';
        }
      ];
      actions = [
        {
          action = "notify.mobile_app_florians_iphone_18";
          data = {
            title = "Window";
            message = "The living room window has been open for {{ ((now() - states.cover.living_room_window.last_changed).total_seconds() // 60) | int }} minutes and it is {{ state_attr('weather.forecast_home', 'temperature') | round(0) | int }} °C outside.";
            data = {
              tag = "window-open";
              actions = [
                {
                  action = "CLOSE_WINDOW";
                  title = "Close it";
                }
              ];
            };
          };
        }
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
    shutters_open_after = {
      has_date = false;
      has_time = true;
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
            selector = {
              select = {
                options = [
                  "privacy"
                  "open"
                  "shade"
                  "closed"
                  "night"
                ];
              };
            };
          };
        }
      ];
      sequence = [
        {
          "if" = [
            {
              condition = "state";
              entity_id = "input_boolean.storm_protection";
              state = "on";
            }
            {
              condition = "template";
              value_template = "{{ (preset | default(\"privacy\")) != \"open\" }}";
            }
          ];
          "then" = [
            {
              action = "notify.mobile_app_florians_iphone_18";
              data = {
                title = "Shutters";
                message = "Storm protection is active, so the blinds stay up. Turn off Storm Protection to lower them anyway.";
                data = {
                  tag = "storm-protection-refused";
                };
              };
            }
            { stop = "Storm protection is active"; }
          ];
        }
        {
          variables = ordered [
            {
              top = [
                "cover.living_room_shutter_top_left"
                "cover.living_room_shutter_top_right"
              ];
            }
            {
              bottom = [
                "cover.living_room_shutter_bottom_left"
                "cover.living_room_shutter_bottom_right"
              ];
            }
            {
              presets = {
                privacy = {
                  top = {
                    position = 100;
                    tilt = 100;
                  };
                  bottom = {
                    position = 0;
                    tilt = 35;
                  };
                };
                open = {
                  top = {
                    position = 100;
                    tilt = 100;
                  };
                  bottom = {
                    position = 100;
                    tilt = 100;
                  };
                };
                shade = {
                  top = {
                    position = 0;
                    tilt = 50;
                  };
                  bottom = {
                    position = 0;
                    tilt = 50;
                  };
                };
                closed = {
                  top = {
                    position = 0;
                    tilt = 0;
                  };
                  bottom = {
                    position = 0;
                    tilt = 0;
                  };
                };
                night = {
                  top = {
                    position = 0;
                    tilt = 0;
                  };
                  bottom = {
                    position = 0;
                    tilt = 35;
                  };
                };
              };
            }
            { layout = "{{ presets[preset | default('privacy')] }}"; }
          ];
        }
        {
          parallel = [
            {
              sequence = [
                {
                  "if" = [
                    {
                      condition = "template";
                      value_template = "{{ layout.top.position == 0 }}";
                    }
                  ];
                  "then" = [
                    {
                      action = "cover_time_based.set_known_position";
                      target = {
                        entity_id = "{{ top }}";
                      };
                      data = {
                        position = 100;
                      };
                    }
                    {
                      action = "cover_time_based.set_known_tilt_position";
                      target = {
                        entity_id = "{{ top }}";
                      };
                      data = {
                        tilt_position = 100;
                      };
                    }
                    {
                      action = "cover.close_cover";
                      target = {
                        entity_id = "{{ top }}";
                      };
                      data = { };
                    }
                  ];
                  "else" = [
                    {
                      action = "cover.set_cover_position";
                      target = {
                        entity_id = "{{ top }}";
                      };
                      data = {
                        position = "{{ layout.top.position }}";
                      };
                    }
                  ];
                }
                {
                  delay = {
                    seconds = 2;
                  };
                }
                {
                  wait_template = "{{ top | reject('is_state', ['opening', 'closing']) | list | count == top | count and top | map('state_attr', 'current_position') | list | select('eq', layout.top.position) | list | count == top | count }}";
                  timeout = {
                    minutes = 2;
                  };
                  continue_on_timeout = false;
                }
                {
                  delay = {
                    seconds = 3;
                  };
                }
                {
                  action = "cover.set_cover_tilt_position";
                  target = {
                    entity_id = "{{ top }}";
                  };
                  data = {
                    tilt_position = "{{ layout.top.tilt }}";
                  };
                }
              ];
            }
            {
              sequence = [
                {
                  "if" = [
                    {
                      condition = "template";
                      value_template = "{{ layout.bottom.position == 0 }}";
                    }
                  ];
                  "then" = [
                    {
                      action = "cover_time_based.set_known_position";
                      target = {
                        entity_id = "{{ bottom }}";
                      };
                      data = {
                        position = 100;
                      };
                    }
                    {
                      action = "cover_time_based.set_known_tilt_position";
                      target = {
                        entity_id = "{{ bottom }}";
                      };
                      data = {
                        tilt_position = 100;
                      };
                    }
                    {
                      action = "cover.close_cover";
                      target = {
                        entity_id = "{{ bottom }}";
                      };
                      data = { };
                    }
                  ];
                  "else" = [
                    {
                      action = "cover.set_cover_position";
                      target = {
                        entity_id = "{{ bottom }}";
                      };
                      data = {
                        position = "{{ layout.bottom.position }}";
                      };
                    }
                  ];
                }
                {
                  delay = {
                    seconds = 2;
                  };
                }
                {
                  wait_template = "{{ bottom | reject('is_state', ['opening', 'closing']) | list | count == bottom | count and bottom | map('state_attr', 'current_position') | list | select('eq', layout.bottom.position) | list | count == bottom | count }}";
                  timeout = {
                    minutes = 2;
                  };
                  continue_on_timeout = false;
                }
                {
                  delay = {
                    seconds = 3;
                  };
                }
                {
                  action = "cover.set_cover_tilt_position";
                  target = {
                    entity_id = "{{ bottom }}";
                  };
                  data = {
                    tilt_position = "{{ layout.bottom.tilt }}";
                  };
                }
              ];
            }
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
            default = [
              "cover.living_room_shutter_top_left"
              "cover.living_room_shutter_top_right"
              "cover.living_room_shutter_bottom_left"
              "cover.living_room_shutter_bottom_right"
            ];
            selector = {
              entity = {
                domain = "cover";
                multiple = true;
              };
            };
          };
        }
      ];
      sequence = [
        {
          variables = ordered [
            {
              targets = "{{ shutters | default(['cover.living_room_shutter_top_left', 'cover.living_room_shutter_top_right', 'cover.living_room_shutter_bottom_left', 'cover.living_room_shutter_bottom_right']) }}";
            }
          ];
        }
        {
          action = "cover_time_based.set_known_position";
          target = {
            entity_id = "{{ targets }}";
          };
          data = {
            position = 100;
          };
        }
        {
          action = "cover_time_based.set_known_tilt_position";
          target = {
            entity_id = "{{ targets }}";
          };
          data = {
            tilt_position = 100;
          };
        }
        {
          action = "cover.close_cover";
          target = {
            entity_id = "{{ targets }}";
          };
          data = { };
        }
      ];
    };
  };
}
