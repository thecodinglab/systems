{ ordered }:
{
  automation = [
    {
      id = "1791906313030";
      alias = "Bedroom: Dial Switch";
      description = "Hue tap dial. 1: toggle (Relax, Night late at night) / long: all lights off (20:00-05:00: Goodnight). 2: Bright. 3: Relax / long: Cozy (candlelight on the back lights). 4: Night / long: room off. Rotary: dim (turns on if off).";
      triggers = [
        {
          trigger = "state";
          entity_id = "event.bedroom_dial_switch_button_1";
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
          entity_id = "event.bedroom_dial_switch_button_2";
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
          entity_id = "event.bedroom_dial_switch_button_3";
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
          entity_id = "event.bedroom_dial_switch_button_4";
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
          entity_id = "event.bedroom_dial_switch_rotary";
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
          action = "script.turn_off";
          target = {
            entity_id = "script.bedroom_sunrise";
          };
        }
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
                      entity_id = "light.bedroom_lights";
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
                      data = {
                        variables = ordered [ { from_bedroom = true; } ];
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
                      entity_id = "light.bedroom_lights";
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
                  value_template = "{{ trigger.id == 'button_3' and event_type in [\"long_press\"] }}";
                }
              ];
              sequence = [
                {
                  action = "script.light_preset";
                  data = {
                    lights = "{{ room_light }}";
                    preset = "cozy";
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
        { room_light = "light.bedroom_lights"; }
        { event_type = "{{ trigger.to_state.attributes.event_type }}"; }
        { steps = "{{ trigger.to_state.attributes.steps | default(0) | int }}"; }
      ];
    }
    {
      id = "1791906313824";
      alias = "Bedroom: Twilight Buttons";
      description = "Button 1: toggle that lamp (main + ambiance, time-of-day preset). Button 2: toggle only that lamp's ambiance light. Long press either: whole bedroom off.";
      triggers = [
        {
          trigger = "state";
          entity_id = "event.bedroom_twilight_left_button_1";
          not_from = [
            "unavailable"
            "unknown"
          ];
          not_to = [
            "unavailable"
            "unknown"
          ];
          id = "left_button_1";
        }
        {
          trigger = "state";
          entity_id = "event.bedroom_twilight_left_button_2";
          not_from = [
            "unavailable"
            "unknown"
          ];
          not_to = [
            "unavailable"
            "unknown"
          ];
          id = "left_button_2";
        }
        {
          trigger = "state";
          entity_id = "event.bedroom_twilight_right_button_1";
          not_from = [
            "unavailable"
            "unknown"
          ];
          not_to = [
            "unavailable"
            "unknown"
          ];
          id = "right_button_1";
        }
        {
          trigger = "state";
          entity_id = "event.bedroom_twilight_right_button_2";
          not_from = [
            "unavailable"
            "unknown"
          ];
          not_to = [
            "unavailable"
            "unknown"
          ];
          id = "right_button_2";
        }
      ];
      actions = [
        {
          action = "script.turn_off";
          target = {
            entity_id = "script.bedroom_sunrise";
          };
        }
        {
          choose = [
            {
              conditions = [
                {
                  condition = "template";
                  value_template = "{{ event_type == \"long_press\" }}";
                }
              ];
              sequence = [
                {
                  action = "light.turn_off";
                  target = {
                    entity_id = "light.bedroom_lights";
                  };
                }
              ];
            }
            {
              conditions = [
                {
                  condition = "template";
                  value_template = "{{ event_type == \"short_release\" and trigger.id.endswith(\"_1\") }}";
                }
              ];
              sequence = [
                {
                  "if" = [
                    {
                      condition = "template";
                      value_template = "{{ is_state(main, \"on\") or is_state(ambiance, \"on\") }}";
                    }
                  ];
                  "then" = [
                    {
                      action = "light.turn_off";
                      target = {
                        entity_id = [
                          "{{ main }}"
                          "{{ ambiance }}"
                        ];
                      };
                    }
                  ];
                  "else" = [
                    {
                      action = "script.light_preset";
                      data = {
                        lights = [
                          "{{ main }}"
                          "{{ ambiance }}"
                        ];
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
                  value_template = "{{ event_type == \"short_release\" and trigger.id.endswith(\"_2\") }}";
                }
              ];
              sequence = [
                {
                  "if" = [
                    {
                      condition = "template";
                      value_template = "{{ is_state(ambiance, \"on\") }}";
                    }
                  ];
                  "then" = [
                    {
                      action = "light.turn_off";
                      target = {
                        entity_id = "{{ ambiance }}";
                      };
                    }
                  ];
                  "else" = [
                    {
                      action = "script.light_preset";
                      data = {
                        lights = "{{ ambiance }}";
                        preset = "auto";
                      };
                    }
                  ];
                }
              ];
            }
          ];
        }
      ];
      mode = "queued";
      max = 5;
      variables = ordered [
        { side = "{{ trigger.id.split(\"_\")[0] }}"; }
        { button = "{{ trigger.id.split(\"_\")[-1] }}"; }
        { event_type = "{{ trigger.to_state.attributes.event_type }}"; }
        { main = "light.bedroom_twilight_{{ side }}_main"; }
        { ambiance = "light.bedroom_twilight_{{ side }}_ambiance"; }
      ];
      max_exceeded = "silent";
    }
    {
      id = "1791906314051";
      alias = "Bedroom: Wake-up Light";
      description = "Starts the 30 min sunrise before the wake-up time configured for that weekday. Only when the master toggle and the day are enabled, you are home, and the bedroom lights are off. Skips one morning when Wake-up Skip Next is on, then resets it.";
      triggers = [
        {
          trigger = "time";
          at = {
            entity_id = "input_datetime.bedroom_wake_up_monday_time";
            offset = "-00:30:00";
          };
          id = "monday";
        }
        {
          trigger = "time";
          at = {
            entity_id = "input_datetime.bedroom_wake_up_tuesday_time";
            offset = "-00:30:00";
          };
          id = "tuesday";
        }
        {
          trigger = "time";
          at = {
            entity_id = "input_datetime.bedroom_wake_up_wednesday_time";
            offset = "-00:30:00";
          };
          id = "wednesday";
        }
        {
          trigger = "time";
          at = {
            entity_id = "input_datetime.bedroom_wake_up_thursday_time";
            offset = "-00:30:00";
          };
          id = "thursday";
        }
        {
          trigger = "time";
          at = {
            entity_id = "input_datetime.bedroom_wake_up_friday_time";
            offset = "-00:30:00";
          };
          id = "friday";
        }
        {
          trigger = "time";
          at = {
            entity_id = "input_datetime.bedroom_wake_up_saturday_time";
            offset = "-00:30:00";
          };
          id = "saturday";
        }
        {
          trigger = "time";
          at = {
            entity_id = "input_datetime.bedroom_wake_up_sunday_time";
            offset = "-00:30:00";
          };
          id = "sunday";
        }
      ];
      conditions = [
        {
          condition = "state";
          entity_id = "input_boolean.bedroom_wake_up_light";
          state = "on";
        }
        {
          condition = "template";
          value_template = "{{ trigger.id == (now() + timedelta(minutes=30)).strftime(\"%A\") | lower }}";
        }
        {
          condition = "template";
          value_template = "{{ is_state(\"input_boolean.bedroom_wake_up_\" ~ trigger.id, \"on\") }}";
        }
      ];
      actions = [
        {
          "if" = [
            {
              condition = "state";
              entity_id = "input_boolean.bedroom_wake_up_skip_next";
              state = "on";
            }
          ];
          "then" = [
            {
              action = "input_boolean.turn_off";
              target = {
                entity_id = "input_boolean.bedroom_wake_up_skip_next";
              };
            }
            { stop = "Skipped once"; }
          ];
        }
        {
          condition = "state";
          entity_id = "person.florian";
          state = "home";
        }
        {
          condition = "state";
          entity_id = "light.bedroom_lights";
          state = "off";
        }
        {
          action = "script.turn_on";
          target = {
            entity_id = "script.bedroom_sunrise";
          };
        }
      ];
      mode = "single";
    }
  ];
  input_boolean = {
    bedroom_wake_up_friday = {
      icon = "mdi:calendar-check";
      name = "Wake-up Friday";
    };
    bedroom_wake_up_light = {
      icon = "mdi:weather-sunset-up";
      name = "Wake-up Light";
    };
    bedroom_wake_up_monday = {
      icon = "mdi:calendar-check";
      name = "Wake-up Monday";
    };
    bedroom_wake_up_saturday = {
      icon = "mdi:calendar-check";
      name = "Wake-up Saturday";
    };
    bedroom_wake_up_skip_next = {
      icon = "mdi:alarm-off";
      name = "Bedroom Wake-up Skip Next";
    };
    bedroom_wake_up_sunday = {
      icon = "mdi:calendar-check";
      name = "Wake-up Sunday";
    };
    bedroom_wake_up_thursday = {
      icon = "mdi:calendar-check";
      name = "Wake-up Thursday";
    };
    bedroom_wake_up_tuesday = {
      icon = "mdi:calendar-check";
      name = "Wake-up Tuesday";
    };
    bedroom_wake_up_wednesday = {
      icon = "mdi:calendar-check";
      name = "Wake-up Wednesday";
    };
  };
  input_datetime = {
    bedroom_wake_up_friday_time = {
      has_date = false;
      has_time = true;
      icon = "mdi:alarm";
      name = "Wake-up Friday Time";
    };
    bedroom_wake_up_monday_time = {
      has_date = false;
      has_time = true;
      icon = "mdi:alarm";
      name = "Wake-up Monday Time";
    };
    bedroom_wake_up_saturday_time = {
      has_date = false;
      has_time = true;
      icon = "mdi:alarm";
      name = "Wake-up Saturday Time";
    };
    bedroom_wake_up_sunday_time = {
      has_date = false;
      has_time = true;
      icon = "mdi:alarm";
      name = "Wake-up Sunday Time";
    };
    bedroom_wake_up_thursday_time = {
      has_date = false;
      has_time = true;
      icon = "mdi:alarm";
      name = "Wake-up Thursday Time";
    };
    bedroom_wake_up_tuesday_time = {
      has_date = false;
      has_time = true;
      icon = "mdi:alarm";
      name = "Wake-up Tuesday Time";
    };
    bedroom_wake_up_wednesday_time = {
      has_date = false;
      has_time = true;
      icon = "mdi:alarm";
      name = "Wake-up Wednesday Time";
    };
  };
  script = {
    bedroom_sunrise = {
      alias = "Bedroom: Sunrise";
      description = "30 min sunrise: the back lights glow deep red-orange on the wall, turn amber and then warm white over 15 min, then the downlights join and everything ends warm-bright (3500 K). Stops if the bedroom lights get turned off. Afterwards the bedroom fades off once you are up (office occupied or a downstairs dial pressed), or after 90 min at the latest. Any bedroom button stops the script, so a light you pick by hand stays on.";
      icon = "mdi:weather-sunset-up";
      mode = "restart";
      sequence = [
        {
          variables = ordered [
            {
              ambiance = [
                "light.bedroom_twilight_left_ambiance"
                "light.bedroom_twilight_right_ambiance"
              ];
            }
            {
              main = [
                "light.bedroom_twilight_left_main"
                "light.bedroom_twilight_right_main"
              ];
            }
          ];
        }
        {
          alias = "Dawn on the wall, deep red-orange back light like the sun below the horizon";
          action = "light.turn_on";
          target = {
            entity_id = "{{ ambiance }}";
          };
          data = {
            brightness_pct = 1;
            xy_color = [
              0.64
              0.35
            ];
            effect = "off";
          };
        }
        {
          delay = {
            seconds = 2;
          };
        }
        {
          action = "light.turn_on";
          target = {
            entity_id = "{{ ambiance }}";
          };
          data = {
            brightness_pct = 35;
            xy_color = [
              0.56
              0.405
            ];
            transition = 600;
          };
        }
        {
          wait_for_trigger = [
            {
              trigger = "state";
              entity_id = "light.bedroom_lights";
              to = "off";
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
              value_template = "{{ wait.trigger is not none }}";
            }
          ];
          "then" = [ { stop = "Bedroom lights were turned off"; } ];
        }
        {
          alias = "Amber turns into warm white";
          action = "light.turn_on";
          target = {
            entity_id = "{{ ambiance }}";
          };
          data = {
            brightness_pct = 70;
            color_temp_kelvin = 2700;
            transition = 300;
          };
        }
        {
          wait_for_trigger = [
            {
              trigger = "state";
              entity_id = "light.bedroom_lights";
              to = "off";
            }
          ];
          timeout = {
            minutes = 5;
          };
          continue_on_timeout = true;
        }
        {
          "if" = [
            {
              condition = "template";
              value_template = "{{ wait.trigger is not none }}";
            }
          ];
          "then" = [ { stop = "Bedroom lights were turned off"; } ];
        }
        {
          alias = "Downlights join, everything ends warm-bright rather than cold daylight";
          action = "light.turn_on";
          target = {
            entity_id = "{{ main }}";
          };
          data = {
            brightness_pct = 1;
            color_temp_kelvin = 2200;
            effect = "off";
          };
        }
        {
          delay = {
            seconds = 2;
          };
        }
        {
          action = "light.turn_on";
          target = {
            entity_id = "{{ main }}";
          };
          data = {
            brightness_pct = 100;
            color_temp_kelvin = 3500;
            transition = 900;
          };
        }
        {
          action = "light.turn_on";
          target = {
            entity_id = "{{ ambiance }}";
          };
          data = {
            brightness_pct = 85;
            color_temp_kelvin = 3000;
            transition = 900;
          };
        }
        {
          wait_for_trigger = [
            {
              trigger = "state";
              entity_id = "light.bedroom_lights";
              to = "off";
            }
          ];
          timeout = {
            minutes = 15;
          };
          continue_on_timeout = true;
        }
        {
          "if" = [
            {
              condition = "template";
              value_template = "{{ wait.trigger is not none }}";
            }
          ];
          "then" = [ { stop = "Bedroom lights were turned off"; } ];
        }
        {
          "if" = [
            {
              condition = "state";
              entity_id = "binary_sensor.office_presence_sensor_occupancy";
              state = "on";
            }
          ];
          "then" = [
            {
              action = "light.turn_off";
              target = {
                entity_id = "light.bedroom_lights";
              };
              data = {
                transition = 30;
              };
            }
            { stop = "Already up and in the office"; }
          ];
        }
        {
          wait_for_trigger = [
            {
              trigger = "state";
              entity_id = "light.bedroom_lights";
              to = "off";
              id = "lights_off";
            }
            {
              trigger = "state";
              entity_id = "binary_sensor.office_presence_sensor_occupancy";
              to = "on";
            }
            {
              trigger = "state";
              entity_id = [
                "event.kitchen_dial_switch_button_1"
                "event.kitchen_dial_switch_button_2"
                "event.kitchen_dial_switch_button_3"
                "event.kitchen_dial_switch_button_4"
                "event.living_room_dial_switch_button_1"
                "event.living_room_dial_switch_button_2"
                "event.living_room_dial_switch_button_3"
                "event.living_room_dial_switch_button_4"
              ];
              not_from = [
                "unavailable"
                "unknown"
              ];
              not_to = [
                "unavailable"
                "unknown"
              ];
            }
          ];
          timeout = {
            minutes = 90;
          };
          continue_on_timeout = true;
        }
        {
          "if" = [
            {
              condition = "template";
              value_template = "{{ wait.trigger is none or wait.trigger.id != 'lights_off' }}";
            }
            {
              condition = "state";
              entity_id = "light.bedroom_lights";
              state = "on";
            }
          ];
          "then" = [
            {
              action = "light.turn_off";
              target = {
                entity_id = "light.bedroom_lights";
              };
              data = {
                transition = 30;
              };
            }
          ];
        }
      ];
    };
  };
}
