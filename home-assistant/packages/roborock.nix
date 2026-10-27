{ ordered }:
{
  automation = [
    {
      id = "1791911060083";
      alias = "Roborock: Notify on Problems";
      description = "Notifies on robot errors, dock errors, low cleaning fluid, full dirty-water tank, empty clean-water tank, water shortage and when the robot is offline. Clears the notification once the problem is resolved. Does not notify on finished cleaning runs.";
      triggers = [
        {
          trigger = "state";
          entity_id = "sensor.living_room_roborock_vacuum_error";
          not_from = [
            "unavailable"
            "unknown"
          ];
          not_to = [
            "unavailable"
            "unknown"
          ];
          for = {
            seconds = 30;
          };
          id = "vacuum_error";
        }
        {
          trigger = "state";
          entity_id = "sensor.living_room_roborock_dock_dock_error";
          not_from = [
            "unavailable"
            "unknown"
          ];
          not_to = [
            "unavailable"
            "unknown"
          ];
          for = {
            seconds = 30;
          };
          id = "dock_error";
        }
        {
          trigger = "state";
          entity_id = "binary_sensor.living_room_roborock_dock_cleaning_fluid";
          not_from = [
            "unavailable"
            "unknown"
          ];
          not_to = [
            "unavailable"
            "unknown"
          ];
          for = {
            seconds = 30;
          };
          id = "cleaning_fluid";
        }
        {
          trigger = "state";
          entity_id = "binary_sensor.living_room_roborock_dock_dirty_water_box";
          not_from = [
            "unavailable"
            "unknown"
          ];
          not_to = [
            "unavailable"
            "unknown"
          ];
          for = {
            seconds = 30;
          };
          id = "dirty_water";
        }
        {
          trigger = "state";
          entity_id = "binary_sensor.living_room_roborock_dock_clean_water_box";
          not_from = [
            "unavailable"
            "unknown"
          ];
          not_to = [
            "unavailable"
            "unknown"
          ];
          for = {
            seconds = 30;
          };
          id = "clean_water";
        }
        {
          trigger = "state";
          entity_id = "binary_sensor.living_room_roborock_water_shortage";
          not_from = [
            "unavailable"
            "unknown"
          ];
          not_to = [
            "unavailable"
            "unknown"
          ];
          for = {
            seconds = 30;
          };
          id = "water_shortage";
        }
        {
          trigger = "state";
          entity_id = "vacuum.living_room_roborock";
          to = "unavailable";
          for = {
            minutes = 30;
          };
          id = "offline";
        }
        {
          trigger = "state";
          entity_id = "vacuum.living_room_roborock";
          from = "unavailable";
          id = "offline";
        }
      ];
      actions = [
        {
          "if" = [
            {
              condition = "template";
              value_template = "{{ problem }}";
            }
          ];
          "then" = [
            {
              action = "notify.mobile_app_florians_iphone_18";
              data = {
                title = "Roborock";
                message = "{{ message }}";
                data = {
                  tag = "{{ tag }}";
                  push = {
                    interruption-level = "{{ \"time-sensitive\" if trigger.id == \"vacuum_error\" else \"active\" }}";
                  };
                };
              };
            }
          ];
          "else" = [
            {
              action = "notify.mobile_app_florians_iphone_18";
              data = {
                message = "clear_notification";
                data = {
                  tag = "{{ tag }}";
                };
              };
            }
          ];
        }
      ];
      mode = "queued";
      variables = ordered [
        { entity = "{{ trigger.entity_id }}"; }
        { state = "{{ trigger.to_state.state }}"; }
        {
          problem = "{{ (state not in [\"none\", \"ok\", \"off\"] and not (trigger.id == \"dock_error\" and state in [\"water_empty\", \"waste_water_tank_full\"])) if trigger.id != \"offline\" else state == \"unavailable\" }}";
        }
        {
          message = "{% if trigger.id == \"vacuum_error\" %}Robot error: {{ state_translated(entity) }}{% elif trigger.id == \"dock_error\" %}Dock: {{ state_translated(entity) }}{% elif trigger.id == \"cleaning_fluid\" %}The dock is running low on cleaning fluid.{% elif trigger.id == \"dirty_water\" %}Empty the dirty-water tank in the dock.{% elif trigger.id == \"clean_water\" %}Refill the clean-water tank in the dock.{% elif trigger.id == \"water_shortage\" %}The robot is out of water. Check the clean-water tank.{% else %}The robot has been offline for 30 minutes.{% endif %}";
        }
        { tag = "roborock-{{ trigger.id }}"; }
      ];
    }
    {
      id = "1792500000010";
      alias = "Roborock: Clean While Away";
      description = "Starts the daily clean once you have been away for 10 minutes (09:00-19:00, or at 09:00 if you left earlier), with \"Roborock Fallback Time\" as a fallback if nothing ran yet today. Arriving home while it is still cleaning asks whether to send it to the dock. Disable the schedule in the Roborock app, otherwise both run.";
      triggers = [
        {
          trigger = "state";
          entity_id = "person.florian";
          from = "home";
          to = "not_home";
          for = {
            minutes = 10;
          };
          id = "away";
        }
        {
          trigger = "time";
          at = "input_datetime.roborock_fallback_time";
          id = "fallback";
        }
        {
          trigger = "time";
          at = "09:00:00";
          id = "window_open";
        }
        {
          trigger = "state";
          entity_id = "person.florian";
          from = "not_home";
          to = "home";
          id = "arrived";
        }
      ];
      actions = [
        {
          choose = [
            {
              conditions = [
                {
                  condition = "trigger";
                  id = [
                    "away"
                    "fallback"
                    "window_open"
                  ];
                }
                {
                  condition = "or";
                  conditions = [
                    {
                      condition = "not";
                      conditions = [
                        {
                          condition = "trigger";
                          id = "window_open";
                        }
                      ];
                    }
                    {
                      condition = "state";
                      entity_id = "person.florian";
                      state = "not_home";
                    }
                  ];
                }
                {
                  condition = "state";
                  entity_id = "vacuum.living_room_roborock";
                  state = "docked";
                }
                {
                  condition = "template";
                  value_template = "{{ not cleaned_today }}";
                }
                {
                  condition = "or";
                  conditions = [
                    {
                      condition = "trigger";
                      id = "fallback";
                    }
                    {
                      condition = "time";
                      after = "09:00:00";
                      before = "19:00:00";
                    }
                  ];
                }
              ];
              sequence = [
                {
                  action = "vacuum.start";
                  target = {
                    entity_id = "vacuum.living_room_roborock";
                  };
                }
              ];
            }
            {
              conditions = [
                {
                  condition = "trigger";
                  id = "arrived";
                }
                {
                  condition = "state";
                  entity_id = "vacuum.living_room_roborock";
                  state = "cleaning";
                }
              ];
              sequence = [
                {
                  action = "notify.mobile_app_florians_iphone_18";
                  data = {
                    title = "Roborock";
                    message = "Welcome home. The Roborock is still cleaning.";
                    data = {
                      tag = "roborock-arrival";
                      actions = [
                        {
                          action = "ROBOROCK_DOCK";
                          title = "Send to dock";
                        }
                      ];
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
          cleaned_today = "{% set b = states('sensor.living_room_roborock_last_clean_begin') | as_datetime(none) %} {{ b is not none and as_local(b).date() == now().date() }}";
        }
      ];
      mode = "single";
    }
    {
      id = "1792500000011";
      alias = "Roborock: Maintenance Reminders";
      description = "Daily at 18:00: one notification per consumable that is (almost) due, with a \"Done\" button that resets its counter. Repeats daily until reset.";
      triggers = [
        {
          trigger = "time";
          at = "18:00:00";
        }
      ];
      conditions = [
        {
          condition = "template";
          value_template = "{{ due | count > 0 }}";
        }
      ];
      actions = [
        {
          repeat = {
            for_each = "{{ due }}";
            sequence = [
              {
                action = "notify.mobile_app_florians_iphone_18";
                data = {
                  title = "Roborock maintenance";
                  message = "{{ repeat.item.name }} ({{ repeat.item.left }} h of cleaning left).";
                  data = {
                    tag = "roborock-{{ repeat.item.button.split('.')[1] }}";
                    actions = [
                      {
                        action = "ROBOROCK_RESET:{{ repeat.item.button }}";
                        title = "Done, reset counter";
                      }
                    ];
                  };
                };
              }
            ];
          };
        }
      ];
      variables = ordered [
        {
          items = [
            {
              name = "Clean the robot's sensors";
              sensor = "sensor.living_room_roborock_sensor_time_left";
              hours = 10;
              button = "button.living_room_roborock_reset_sensor_consumable";
            }
            {
              name = "Clean or replace the side brush";
              sensor = "sensor.living_room_roborock_side_brush_time_left";
              hours = 24;
              button = "button.living_room_roborock_reset_side_brush_consumable";
            }
            {
              name = "Clean or replace the main brush";
              sensor = "sensor.living_room_roborock_main_brush_time_left";
              hours = 24;
              button = "button.living_room_roborock_reset_main_brush_consumable";
            }
            {
              name = "Replace the air filter";
              sensor = "sensor.living_room_roborock_filter_time_left";
              hours = 24;
              button = "button.living_room_roborock_reset_air_filter_consumable";
            }
            {
              name = "Clean the dock strainer";
              sensor = "sensor.living_room_roborock_dock_strainer_time_left";
              hours = 10;
              button = "button.living_room_roborock_dock_reset_strainer_consumable";
            }
            {
              name = "Clean the dock's maintenance brush";
              sensor = "sensor.living_room_roborock_dock_maintenance_brush_time_left";
              hours = 10;
              button = "button.living_room_roborock_dock_reset_cleaning_brush_consumable";
            }
          ];
        }
        {
          due = ''
            {%- set ns = namespace(l=[]) -%} {%- for i in items if has_value(i.sensor) -%}
              {%- set v = states(i.sensor) | float(0) -%}
              {%- set h = v / 3600 if state_attr(i.sensor, 'unit_of_measurement') == 's' else v -%}
              {%- if h < i.hours -%}{%- set ns.l = ns.l + [dict(i, left=h | round(0) | int)] -%}{%- endif -%}
            {%- endfor -%} {{ ns.l }}'';
        }
      ];
      mode = "single";
    }
  ];
  input_datetime = {
    roborock_fallback_time = {
      has_date = false;
      has_time = true;
      icon = "mdi:robot-vacuum";
      initial = "14:00:00";
      name = "Roborock Fallback Time";
    };
  };
}
