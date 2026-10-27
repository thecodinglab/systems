{ ordered }:
{
  automation = [
    {
      id = "1753172024868";
      alias = "Office: Light On When Occupied";
      description = "Turns the office lamp on when someone is at the desk and it is dark enough. Not while night mode is on.";
      triggers = [
        {
          trigger = "state";
          entity_id = "binary_sensor.office_presence_sensor_occupancy";
          from = "off";
          to = "on";
        }
      ];
      conditions = [
        {
          condition = "state";
          entity_id = "input_boolean.office_light_override";
          state = "off";
        }
        {
          condition = "numeric_state";
          entity_id = "sensor.office_presence_sensor_illuminance";
          below = 150;
        }
        {
          condition = "state";
          entity_id = "input_boolean.night_mode";
          state = "off";
        }
      ];
      actions = [
        {
          action = "light.turn_on";
          target = {
            entity_id = "light.office_lights";
          };
        }
      ];
      mode = "single";
    }
    {
      id = "1753172088711";
      alias = "Office: Light Off When Vacant";
      description = "";
      triggers = [
        {
          trigger = "state";
          entity_id = "binary_sensor.office_presence_sensor_occupancy";
          to = "off";
          for = {
            minutes = 5;
          };
        }
      ];
      conditions = [
        {
          condition = "state";
          entity_id = "input_boolean.office_light_override";
          state = "off";
        }
      ];
      actions = [
        {
          action = "light.turn_off";
          target = {
            entity_id = "light.office_lights";
          };
        }
      ];
      mode = "single";
    }
    {
      id = "1792500000009";
      alias = "Office: Turn Off Other Rooms While Working";
      description = "After 15 minutes of continuous presence in the office, turns off the kitchen and living room lights, and between 08:00 and 19:00 also the bedroom (unless the wake-up sunrise is running).";
      triggers = [
        {
          trigger = "state";
          entity_id = "binary_sensor.office_presence_sensor_occupancy";
          to = "on";
          for = {
            minutes = 15;
          };
        }
      ];
      conditions = [
        {
          condition = "state";
          entity_id = "person.florian";
          state = "home";
        }
        {
          condition = "state";
          entity_id = "input_boolean.night_mode";
          state = "off";
        }
      ];
      actions = [
        {
          variables = ordered [
            {
              bedroom_ok = ''
                {{ today_at('08:00') <= now() < today_at('19:00')
                   and is_state('script.bedroom_sunrise', 'off') }}'';
            }
            {
              targets = ''
                {{ (['light.kitchen_lights', 'light.living_room_lights']
                    + (['light.bedroom_lights'] if bedroom_ok else []))
                   | select('is_state', 'on') | list }}'';
            }
          ];
        }
        {
          condition = "template";
          value_template = "{{ targets | count > 0 }}";
        }
        {
          action = "light.turn_off";
          target = {
            entity_id = "{{ targets }}";
          };
          data = {
            transition = 5;
          };
        }
      ];
      mode = "single";
    }
    {
      id = "1792500000012";
      alias = "Office: Wake Desktop When Entering";
      description = "Sends Wake-on-LAN when someone enters the office and the desktop is asleep (plug below 60 W), between 06:00 and 23:00 and not in night mode.";
      triggers = [
        {
          trigger = "state";
          entity_id = "binary_sensor.office_presence_sensor_occupancy";
          from = "off";
          to = "on";
        }
      ];
      conditions = [
        {
          condition = "time";
          after = "06:00:00";
          before = "23:00:00";
        }
        {
          condition = "state";
          entity_id = "input_boolean.night_mode";
          state = "off";
        }
        {
          condition = "state";
          entity_id = "switch.office_desktop";
          state = "on";
        }
        {
          condition = "numeric_state";
          entity_id = "sensor.office_desktop_power";
          below = 60;
        }
      ];
      actions = [
        {
          action = "button.press";
          target = {
            entity_id = "button.office_desktop_wake_on_lan";
          };
        }
      ];
      mode = "single";
      max_exceeded = "silent";
    }
  ];
  input_boolean = {
    office_light_override = {
      icon = "mdi:lightbulb-auto-outline";
      name = "Light Override";
    };
  };
}
