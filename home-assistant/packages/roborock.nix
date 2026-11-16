{
  lib,
  entities,
  ordered,
  changed,
  state,
  notState,
  template,
  nobodyHome,
  onePersonHome,
  left,
  arrived,
  call,
  notify,
  clearNotification,
  timeOfDay,
  ...
}:
let
  inherit (entities) person vacuum scripts;

  weekdays = [
    "Monday"
    "Tuesday"
    "Wednesday"
    "Thursday"
    "Friday"
    "Saturday"
    "Sunday"
  ];
  # the daily clean only mops on these days, the others vacuum only
  mopDays = [
    "Monday"
    "Thursday"
  ];
  # python's weekday() of each, 0 is monday
  mopWeekdays = map (
    day: lib.lists.findFirstIndex (d: d == day) (throw "unknown weekday ${day}") weekdays
  ) mopDays;

  cleaningMode = "select.living_room_roborock_cleaning_mode";
  selectedMap = "select.living_room_roborock_selected_map";
  # dock actions: on starts the job, the state is on while it runs
  dustEmptying = "switch.living_room_roborock_dock_dust_emptying";
  mopWashing = "switch.living_room_roborock_dock_mop_washing";
  mopDrying = "switch.living_room_roborock_dock_mop_drying";
  # when the upstairs clean started, so the daily clean doesn't take it for
  # its own run
  upstairsStarted = "input_datetime.roborock_upstairs_started";

  selectOption =
    entity: option: call "select.select_option" entity // { data = { inherit option; }; };
  loadMap = name: {
    "if" = [ (template "{{ not is_state('${selectedMap}', '${name}') }}") ];
    "then" = [ (selectOption selectedMap name) ];
  };
  # runs a dock job and waits for it; a short job can be over before the
  # integration has seen it running, so not seeing it start is fine
  dockJob = switch: [
    (call "switch.turn_on" switch)
    {
      wait_template = "{{ is_state('${switch}', 'on') }}";
      timeout.minutes = 1;
      continue_on_timeout = true;
    }
    {
      wait_template = "{{ is_state('${switch}', 'off') }}";
      timeout.minutes = 30;
      continue_on_timeout = true;
    }
  ];
  upstairsTag = "roborock-upstairs";
  stopDrying = {
    "if" = [ (state mopDrying "on") ];
    "then" = [
      (call "switch.turn_off" mopDrying)
      { delay.seconds = 5; }
    ];
  };

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
      description = "Starts the daily clean once the last person has been away for 10 minutes (09:00-19:00, or at 09:00 if everyone left earlier), with \"Roborock Fallback Time\" as a fallback if nothing ran yet today (also while someone is home). Mops on ${lib.concatStringsSep " and " mopDays}, vacuums only on the other days. An upstairs clean doesn't count as the daily one, and nothing happens while it is in progress. When the first person comes home while it is still cleaning, asks me whether to send it to the dock. Disable the schedule in the Roborock app, otherwise both run.";
      conditions = [ (state scripts.roborockUpstairs "off") ];
      triggers = [
        (left {
          for.minutes = 10;
          id = "away";
        })
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
        (arrived { id = "arrived"; })
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
                      condition = "trigger";
                      id = "fallback";
                    }
                    nobodyHome
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
              sequence = [
                {
                  action = scripts.roborockClean;
                  data.mop = "{{ mop_day }}";
                }
              ];
            }
            {
              conditions = [
                {
                  condition = "trigger";
                  id = "arrived";
                }
                (state vacuum "cleaning")
                (onePersonHome // { alias = "The first one home"; })
              ];
              sequence = [
                (notify {
                  title = "Roborock";
                  message = "{{ 'Welcome home.' if trigger.entity_id == '${person}' else trigger.to_state.name ~ ' is home.' }} The Roborock is still cleaning.";
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
          # a run that began within 10 min of the upstairs clean is that one
          cleaned_today = ''
            {%- set b = states('sensor.living_room_roborock_last_clean_begin') | as_datetime(none) -%}
            {%- set u = state_attr('${upstairsStarted}', 'timestamp') | float(0) -%}
            {{ b is not none and as_local(b).date() == now().date()
               and (as_timestamp(b) - u) | abs > 600 }}'';
        }
        { mop_day = "{{ now().weekday() in ${builtins.toJSON mopWeekdays} }}"; }
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
  script = {
    roborock_clean = {
      alias = "Roborock Clean";
      description = "Cleans downstairs, vacuum only or vacuum and mop. Sets the cleaning mode every time, since the robot keeps the last one. Does nothing while an upstairs clean is in progress.";
      icon = "mdi:robot-vacuum";
      mode = "single";
      max_exceeded = "silent";
      fields = ordered [
        {
          mop = {
            name = "Mop";
            description = "Vacuum and mop instead of vacuum only.";
            default = false;
            selector.boolean = null;
          };
        }
      ];
      sequence = [
        (state scripts.roborockUpstairs "off")
        (loadMap "Downstairs")
        (selectOption cleaningMode "{{ 'vac_and_mop' if mop | bool(false) else 'vacuum' }}")
        (call "vacuum.start" vacuum)
      ];
    };

    roborock_upstairs = {
      alias = "Roborock Upstairs";
      description = "Upstairs clean, where there is no dock: washes the mop, asks me to carry the robot upstairs and tap Start (or start it on the robot or in the app), vacuums and mops the Upstairs map, asks me to carry it back down and, once it is on the dock again, loads the Downstairs map, empties the dustbin and washes and dries the mop.";
      icon = "mdi:stairs-up";
      mode = "single";
      max_exceeded = "silent";
      sequence = [
        {
          "if" = [ (notState vacuum "docked") ];
          "then" = [
            (notify {
              title = "Roborock";
              message = "Put the Roborock on the dock first, an upstairs clean starts with washing the mop.";
              tag = upstairsTag;
            })
            { stop = "Not on the dock"; }
          ];
        }
      ]
      # it may still be drying from the last run
      ++ [ stopDrying ]
      ++ dockJob mopWashing
      ++ [
        # and may start drying after the wash, pointless without the robot
        stopDrying
        # until it is off the dock or was started some other way (its own
        # button, the app)
        {
          repeat = {
            sequence = [
              (notify {
                title = "Roborock";
                message = "{{ 'The Roborock is still on the dock.' if repeat.index > 1 else 'The mop is clean.' }} Carry it upstairs, then tap Start (or start it on the robot).";
                tag = upstairsTag;
                actions = [
                  {
                    action = "ROBOROCK_UPSTAIRS_START";
                    title = "Start";
                  }
                  {
                    action = "ROBOROCK_UPSTAIRS_CANCEL";
                    title = "Cancel";
                  }
                ];
              })
              {
                wait_for_trigger = [
                  {
                    trigger = "event";
                    event_type = "mobile_app_notification_action";
                    event_data.action = "ROBOROCK_UPSTAIRS_START";
                    id = "start";
                  }
                  {
                    trigger = "event";
                    event_type = "mobile_app_notification_action";
                    event_data.action = "ROBOROCK_UPSTAIRS_CANCEL";
                    id = "cancel";
                  }
                  # started off the dock, not a downstairs run from the dock
                  {
                    trigger = "state";
                    entity_id = vacuum;
                    to = "cleaning";
                    not_from = "docked";
                    id = "started";
                  }
                ];
                timeout.hours = 3;
                continue_on_timeout = true;
              }
              {
                "if" = [ (template "{{ wait.trigger is none or wait.trigger.id == 'cancel' }}") ];
                "then" = [
                  (clearNotification upstairsTag)
                  { stop = "Cancelled"; }
                ];
              }
            ];
            until = [ (notState vacuum "docked") ];
          };
        }
        (clearNotification upstairsTag)
        {
          "if" = [ (notState vacuum "cleaning") ];
          "then" = [
            (loadMap "Upstairs")
            (selectOption cleaningMode "vac_and_mop")
            (call "vacuum.start" vacuum)
            {
              wait_template = "{{ is_state('${vacuum}', 'cleaning') }}";
              timeout.minutes = 2;
              continue_on_timeout = true;
            }
            {
              "if" = [ (template "{{ not wait.completed }}") ];
              "then" = [
                (notify {
                  title = "Roborock";
                  message = "The Roborock didn't start cleaning upstairs. Check the Roborock app, then carry it back to the dock.";
                  tag = upstairsTag;
                })
                { stop = "Didn't start"; }
              ];
            }
          ];
        }
        (
          call "input_datetime.set_datetime" upstairsStarted
          // {
            data.timestamp = "{{ now().timestamp() }}";
          }
        )
        {
          wait_template = "{{ states('${vacuum}') not in ['cleaning', 'returning', 'paused'] }}";
          timeout.hours = 4;
          continue_on_timeout = true;
        }
        (notify {
          title = "Roborock";
          message = "{{ 'The Roborock is done upstairs.' if is_state('${vacuum}', 'idle') else 'The Roborock has stopped upstairs.' }} Carry it back to the dock.";
          tag = upstairsTag;
        })
        {
          wait_template = "{{ is_state('${vacuum}', 'docked') }}";
          timeout.hours = 8;
          continue_on_timeout = false;
        }
        (clearNotification upstairsTag)
        (loadMap "Downstairs")
      ]
      ++ dockJob dustEmptying
      ++ dockJob mopWashing
      ++ [
        # unless the dock started drying by itself after the wash
        { delay.seconds = 30; }
        {
          "if" = [ (state mopDrying "off") ];
          "then" = [ (call "switch.turn_on" mopDrying) ];
        }
      ];
    };
  };

  input_datetime = {
    roborock_fallback_time = timeOfDay {
      icon = "mdi:robot-vacuum";
      initial = "14:00:00";
      name = "Roborock Fallback Time";
    };
    roborock_upstairs_started = {
      has_date = true;
      has_time = true;
      icon = "mdi:stairs-up";
      name = "Roborock Upstairs Started";
    };
  };
}
