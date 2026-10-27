{
  entities,
  ordered,
  isHome,
  nightModeOff,
  notify,
  clearNotification,
  ...
}:
let
  inherit (entities) weather;

  humidity = "sensor.bathroom_climate_humidity";

  # absolute humidity in g/m³ from the temperature (°C) and relative humidity
  absoluteHumidity =
    t: rh:
    "{{ (6.112 * e ** ((17.67 * ${t}) / (${t} + 243.5)) * ${rh} * 2.1674 / (273.15 + ${t})) | round(1) }}";
in
{
  automation = [
    {
      id = "1792500000014";
      alias = "Bathroom: Humidity Alert";
      description = "Above 70 % for 20 minutes (after a shower) or above 65 % for 2 hours (damp that is not drying): tells you to air the bathroom, and whether the outside air is actually drier (absolute humidity). Clears once it is below 60 %.";
      triggers = [
        {
          trigger = "numeric_state";
          entity_id = humidity;
          above = 70;
          for.minutes = 20;
          id = "shower";
        }
        {
          trigger = "numeric_state";
          entity_id = humidity;
          above = 65;
          for.hours = 2;
          id = "damp";
        }
      ];
      conditions = [
        isHome
        nightModeOff
      ];
      actions = [
        {
          variables = ordered [
            { rh_in = "{{ states('${humidity}') | float(0) }}"; }
            { t_in = "{{ states('sensor.bathroom_climate_temperature') | float(21) }}"; }
            { rh_out = "{{ state_attr('${weather}', 'humidity') | float(80) }}"; }
            { t_out = "{{ state_attr('${weather}', 'temperature') | float(10) }}"; }
            { ah_in = absoluteHumidity "t_in" "rh_in"; }
            { ah_out = absoluteHumidity "t_out" "rh_out"; }
          ];
        }
        (notify {
          title = "Bathroom humidity {{ rh_in | round(0) | int }} %";
          message = "{% if ah_out < ah_in - 1 %}Open the window for 10 minutes: the outside air is drier ({{ ah_out }} vs {{ ah_in }} g/m³).{% else %}The outside air is just as humid ({{ ah_out }} vs {{ ah_in }} g/m³), so airing won't help much. Leave the door open and keep it warm.{% endif %}";
          tag = "bathroom-humidity";
        })
        {
          wait_for_trigger = [
            {
              trigger = "numeric_state";
              entity_id = humidity;
              below = 60;
              for.minutes = 10;
            }
          ];
          timeout.hours = 6;
          continue_on_timeout = true;
        }
        (clearNotification "bathroom-humidity")
      ];
      mode = "single";
      max_exceeded = "silent";
    }
  ];
}
