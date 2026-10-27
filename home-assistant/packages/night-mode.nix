{ ordered }:
{
  automation = [
    {
      id = "1792500000003";
      alias = "Night Mode: End in the Morning";
      description = "Turns night mode off at 05:00, before the earliest wake-up light starts.";
      triggers = [
        {
          trigger = "time";
          at = "05:00:00";
        }
      ];
      conditions = [
        {
          condition = "state";
          entity_id = "input_boolean.night_mode";
          state = "on";
        }
      ];
      actions = [
        {
          action = "input_boolean.turn_off";
          target = {
            entity_id = "input_boolean.night_mode";
          };
        }
      ];
      mode = "single";
    }
  ];
  input_boolean = {
    night_mode = {
      icon = "mdi:weather-night";
      name = "Night Mode";
    };
  };
  script = {
    goodnight = {
      alias = "Goodnight";
      description = "Bedtime in one step: switches on night mode (keeps the office lamp from turning itself on until 05:00), turns off downstairs and the office, closes the living room window, turns the bedroom on with the evening preset if it is off (left as it is when called from the bedroom dial), and shows tomorrow's wake-up light with a button to skip it.";
      icon = "mdi:weather-night";
      mode = "single";
      fields = ordered [
        {
          from_bedroom = {
            name = "Called from the bedroom";
            description = "Leave the bedroom lights as they are instead of turning them on.";
            default = false;
            selector = {
              boolean = null;
            };
          };
        }
      ];
      sequence = [
        {
          action = "input_boolean.turn_on";
          target = {
            entity_id = "input_boolean.night_mode";
          };
        }
        {
          action = "light.turn_off";
          target = {
            entity_id = [
              "light.kitchen_lights"
              "light.living_room_lights"
              "light.office_lights"
            ];
          };
          data = {
            transition = 3;
          };
        }
        {
          "if" = [
            {
              condition = "template";
              value_template = "{{ not (from_bedroom | default(false)) }}";
            }
            {
              condition = "state";
              entity_id = "light.bedroom_lights";
              state = "off";
            }
          ];
          "then" = [
            {
              action = "script.light_preset";
              data = {
                lights = "light.bedroom_lights";
                preset = "auto";
                transition = 2;
              };
            }
          ];
        }
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
          variables = ordered [
            { day = "{{ (now() + timedelta(days=0 if now().hour < 5 else 1)).strftime('%A') | lower }}"; }
            {
              scheduled = ''
                {{ is_state('input_boolean.bedroom_wake_up_light', 'on')
                   and is_state('input_boolean.bedroom_wake_up_' ~ day, 'on') }}'';
            }
            { skipped = "{{ is_state('input_boolean.bedroom_wake_up_skip_next', 'on') }}"; }
            { wake_time = "{{ states('input_datetime.bedroom_wake_up_' ~ day ~ '_time')[:5] }}"; }
          ];
        }
        {
          "if" = [
            {
              condition = "template";
              value_template = "{{ scheduled }}";
            }
          ];
          "then" = [
            {
              action = "notify.mobile_app_florians_iphone_18";
              data = {
                title = "Goodnight";
                message = ''
                  {{ 'Wake-up light is skipped tomorrow.' if skipped
                     else 'Wake-up light tomorrow at ' ~ wake_time ~ '.' }}'';
                data = {
                  tag = "wake-up-tomorrow";
                  actions = [
                    {
                      action = "{{ 'WAKEUP_UNSKIP' if skipped else 'WAKEUP_SKIP_NEXT' }}";
                      title = "{{ 'Wake me after all' if skipped else 'Skip tomorrow' }}";
                    }
                  ];
                };
              };
            }
          ];
        }
      ];
    };
  };
}
