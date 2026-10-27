{
  entities,
  ordered,
  jinjaList,
  state,
  notState,
  template,
  call,
  notify,
  lightPreset,
  ...
}:
let
  inherit (entities) person lights window;

  # turned on when arriving after dark
  welcome = [
    lights.livingRoom
    lights.kitchen
  ];
in
{
  automation = [
    {
      id = "1767878609705";
      alias = "Presence: Leaving Home";
      description = "Two minutes after leaving home: turns off all lights, ends night mode and closes the living room window if it is open. Uses a home -> not_home state change, so a restart (home -> unknown -> home) no longer counts as leaving.";
      triggers = [
        {
          trigger = "state";
          entity_id = person;
          from = "home";
          to = "not_home";
          for.minutes = 2;
        }
      ];
      actions = [
        (call "light.turn_off" entities.allLights)
        (call "input_boolean.turn_off" entities.nightMode)
        {
          "if" = [ (notState window "closed") ];
          "then" = [
            (call "cover.close_cover" window)
            (notify {
              title = "Window";
              message = "You left with the living room window open, so it has been closed.";
              tag = "window-closed-leaving";
            })
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
          entity_id = person;
          from = "not_home";
          to = "home";
        }
      ];
      conditions = [
        (template "{{ (trigger.to_state.last_changed - trigger.from_state.last_changed).total_seconds() > 600 }}")
        (state "sun.sun" "below_horizon")
      ];
      actions = [
        {
          variables = ordered [
            {
              targets = "{{ ${jinjaList welcome} | select('is_state', 'off') | list }}";
            }
          ];
        }
        (template "{{ targets | count > 0 }}")
        (lightPreset {
          lights = "{{ targets }}";
          preset = "{{ 'bright' if 5 <= now().hour < 12 else 'relax' }}";
          transition = 1;
        })
      ];
      mode = "single";
    }
  ];
}
