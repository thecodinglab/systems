{ ordered }:
{
  automation = [
    {
      id = "1791906312244";
      alias = "Kitchen: Dial Switch";
      description = "Hue tap dial. 1: toggle (time-of-day preset) / long: all lights off (20:00-05:00: Goodnight). 2: Bright. 3: Relax. 4: Night / long: room off. Rotary: dim (turns on if off).";
      triggers = [
        {
          trigger = "state";
          entity_id = "event.kitchen_dial_switch_button_1";
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
          entity_id = "event.kitchen_dial_switch_button_2";
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
          entity_id = "event.kitchen_dial_switch_button_3";
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
          entity_id = "event.kitchen_dial_switch_button_4";
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
          entity_id = "event.kitchen_dial_switch_rotary";
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
                      entity_id = "light.kitchen_lights";
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
                      entity_id = "light.kitchen_lights";
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
          ];
        }
      ];
      mode = "queued";
      max = 10;
      max_exceeded = "silent";
      variables = ordered [
        { room_light = "light.kitchen_lights"; }
        { event_type = "{{ trigger.to_state.attributes.event_type }}"; }
        { steps = "{{ trigger.to_state.attributes.steps | default(0) | int }}"; }
      ];
    }
  ];
}
