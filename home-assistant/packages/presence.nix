{ ordered }:
{
  automation = [
    {
      id = "1767878609705";
      alias = "Presence: Leaving Home";
      description = "Two minutes after leaving home: turns off all lights, ends night mode and closes the living room window if it is open. Uses a home -> not_home state change, so a restart (home -> unknown -> home) no longer counts as leaving.";
      triggers = [
        {
          trigger = "state";
          entity_id = "person.florian";
          from = "home";
          to = "not_home";
          for = {
            minutes = 2;
          };
        }
      ];
      actions = [
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
        {
          action = "input_boolean.turn_off";
          target = {
            entity_id = "input_boolean.night_mode";
          };
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
            {
              action = "notify.mobile_app_florians_iphone_18";
              data = {
                title = "Window";
                message = "You left with the living room window open, so it has been closed.";
                data = {
                  tag = "window-closed-leaving";
                };
              };
            }
          ];
        }
      ];
      mode = "single";
    }
    {
      id = "1792500000002";
      alias = "Presence: Welcome Home After Dark";
      description = "Arriving home after dark turns on the living room and kitchen with the Relax preset (Bright in the early morning). Ignores location blips shorter than 10 minutes and the restart flip from unknown.";
      triggers = [
        {
          trigger = "state";
          entity_id = "person.florian";
          from = "not_home";
          to = "home";
        }
      ];
      conditions = [
        {
          condition = "template";
          value_template = "{{ (trigger.to_state.last_changed - trigger.from_state.last_changed).total_seconds() > 600 }}";
        }
        {
          condition = "state";
          entity_id = "sun.sun";
          state = "below_horizon";
        }
      ];
      actions = [
        {
          variables = ordered [
            {
              targets = "{{ ['light.living_room_lights', 'light.kitchen_lights'] | select('is_state', 'off') | list }}";
            }
          ];
        }
        {
          condition = "template";
          value_template = "{{ targets | count > 0 }}";
        }
        {
          action = "script.light_preset";
          data = {
            lights = "{{ targets }}";
            preset = "{{ 'bright' if 5 <= now().hour < 12 else 'relax' }}";
            transition = 1;
          };
        }
      ];
      mode = "single";
    }
  ];
}
