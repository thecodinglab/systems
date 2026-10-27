{ ordered }:
{
  automation = [
    {
      id = "1792500000014";
      alias = "Bathroom: Humidity Alert";
      description = "Above 70 % for 20 minutes (after a shower) or above 65 % for 2 hours (damp that is not drying): tells you to air the bathroom, and whether the outside air is actually drier (absolute humidity). Clears once it is below 60 %.";
      triggers = [
        {
          trigger = "numeric_state";
          entity_id = "sensor.bathroom_climate_humidity";
          above = 70;
          for = {
            minutes = 20;
          };
          id = "shower";
        }
        {
          trigger = "numeric_state";
          entity_id = "sensor.bathroom_climate_humidity";
          above = 65;
          for = {
            hours = 2;
          };
          id = "damp";
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
            { rh_in = "{{ states('sensor.bathroom_climate_humidity') | float(0) }}"; }
            { t_in = "{{ states('sensor.bathroom_climate_temperature') | float(21) }}"; }
            { rh_out = "{{ state_attr('weather.forecast_home', 'humidity') | float(80) }}"; }
            { t_out = "{{ state_attr('weather.forecast_home', 'temperature') | float(10) }}"; }
            {
              ah_in = "{{ (6.112 * e ** ((17.67 * t_in) / (t_in + 243.5)) * rh_in * 2.1674 / (273.15 + t_in)) | round(1) }}";
            }
            {
              ah_out = "{{ (6.112 * e ** ((17.67 * t_out) / (t_out + 243.5)) * rh_out * 2.1674 / (273.15 + t_out)) | round(1) }}";
            }
          ];
        }
        {
          action = "notify.mobile_app_florians_iphone_18";
          data = {
            title = "Bathroom humidity {{ rh_in | round(0) | int }} %";
            message = "{% if ah_out < ah_in - 1 %}Open the window for 10 minutes: the outside air is drier ({{ ah_out }} vs {{ ah_in }} g/m³).{% else %}The outside air is just as humid ({{ ah_out }} vs {{ ah_in }} g/m³), so airing won't help much. Leave the door open and keep it warm.{% endif %}";
            data = {
              tag = "bathroom-humidity";
            };
          };
        }
        {
          wait_for_trigger = [
            {
              trigger = "numeric_state";
              entity_id = "sensor.bathroom_climate_humidity";
              below = 60;
              for = {
                minutes = 10;
              };
            }
          ];
          timeout = {
            hours = 6;
          };
          continue_on_timeout = true;
        }
        {
          action = "notify.mobile_app_florians_iphone_18";
          data = {
            message = "clear_notification";
            data = {
              tag = "bathroom-humidity";
            };
          };
        }
      ];
      mode = "single";
      max_exceeded = "silent";
    }
  ];
}
