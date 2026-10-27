{
  lib,
  entities,
  ordered,
  changed,
  state,
  template,
  call,
  notify,
  clearNotification,
  timeOfDay,
  ...
}:
let
  inherit (entities) person vacuum;

  # problems worth a notification, by trigger id; `message` is a template
  # that can use `entity`
  problems = [
    {
      id = "vacuum_error";
      entity = "sensor.living_room_roborock_vacuum_error";
      message = "Robot error: {{ state_translated(entity) }}";
    }
    {
      id = "dock_error";
      entity = "sensor.living_room_roborock_dock_dock_error";
      message = "Dock: {{ state_translated(entity) }}";
    }
    {
      id = "cleaning_fluid";
      entity = "binary_sensor.living_room_roborock_dock_cleaning_fluid";
      message = "The dock is running low on cleaning fluid.";
    }
    {
      id = "dirty_water";
      entity = "binary_sensor.living_room_roborock_dock_dirty_water_box";
      message = "Empty the dirty-water tank in the dock.";
    }
    {
      id = "clean_water";
      entity = "binary_sensor.living_room_roborock_dock_clean_water_box";
      message = "Refill the clean-water tank in the dock.";
    }
    {
      id = "water_shortage";
      entity = "binary_sensor.living_room_roborock_water_shortage";
      message = "The robot is out of water. Check the clean-water tank.";
    }
  ];
in
{
  automation = [
    {
      id = "1791911060083";
      alias = "Roborock: Notify on Problems";
      description = "Notifies on robot errors, dock errors, low cleaning fluid, full dirty-water tank, empty clean-water tank, water shortage and when the robot is offline. Clears the notification once the problem is resolved. Does not notify on finished cleaning runs.";
      triggers =
        map (
          problem:
          changed problem.entity {
            for.seconds = 30;
            inherit (problem) id;
          }
        ) problems
        ++ [
          {
            trigger = "state";
            entity_id = vacuum;
            to = "unavailable";
            for.minutes = 30;
            id = "offline";
          }
          {
            trigger = "state";
            entity_id = vacuum;
            from = "unavailable";
            id = "offline";
          }
        ];
      actions = [
        {
          "if" = [ (template "{{ problem }}") ];
          "then" = [
            (notify {
              title = "Roborock";
              message = "{{ message }}";
              tag = "{{ tag }}";
              interruptionLevel = "{{ \"time-sensitive\" if trigger.id == \"vacuum_error\" else \"active\" }}";
            })
          ];
          "else" = [ (clearNotification "{{ tag }}") ];
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
          message =
            lib.concatStrings (
              lib.imap0 (
                i: problem:
                "{% ${if i == 0 then "if" else "elif"} trigger.id == \"${problem.id}\" %}${problem.message}"
              ) problems
            )
            + "{% else %}The robot has been offline for 30 minutes.{% endif %}";
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
          entity_id = person;
          from = "home";
          to = "not_home";
          for.minutes = 10;
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
          entity_id = person;
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
                    (state person "not_home")
                  ];
                }
                (state vacuum "docked")
                (template "{{ not cleaned_today }}")
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
              sequence = [ (call "vacuum.start" vacuum) ];
            }
            {
              conditions = [
                {
                  condition = "trigger";
                  id = "arrived";
                }
                (state vacuum "cleaning")
              ];
              sequence = [
                (notify {
                  title = "Roborock";
                  message = "Welcome home. The Roborock is still cleaning.";
                  tag = "roborock-arrival";
                  actions = [
                    {
                      action = "ROBOROCK_DOCK";
                      title = "Send to dock";
                    }
                  ];
                })
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
      conditions = [ (template "{{ due | count > 0 }}") ];
      actions = [
        {
          repeat = {
            for_each = "{{ due }}";
            sequence = [
              (notify {
                title = "Roborock maintenance";
                message = "{{ repeat.item.name }} ({{ repeat.item.left }} h of cleaning left).";
                tag = "roborock-{{ repeat.item.button.split('.')[1] }}";
                actions = [
                  {
                    action = "ROBOROCK_RESET:{{ repeat.item.button }}";
                    title = "Done, reset counter";
                  }
                ];
              })
            ];
          };
        }
      ];
      variables = ordered [
        {
          # remind when less than `hours` of cleaning are left
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
    roborock_fallback_time = timeOfDay {
      icon = "mdi:robot-vacuum";
      initial = "14:00:00";
      name = "Roborock Fallback Time";
    };
  };
}
