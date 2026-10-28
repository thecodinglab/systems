{ entities, ... }:
let
  inherit (import ./cards.nix)
    section
    heading
    markdown
    half
    full
    ;

  # a helper that is changed right on the tile
  setting =
    icon: name: entity:
    full { inherit icon name entity; };

  roborock =
    icon: name: part:
    half {
      inherit icon name;
      entity = "sensor.living_room_roborock_${part}_time_left";
    };
in
{
  title = "Automations";
  path = "automations";
  icon = "mdi:robot";
  type = "sections";
  max_columns = 3;
  sections = [
    (section [
      (heading "mdi:palette" "Light presets")
      (markdown "The **auto** preset (button 1 and the dial) is Bright during the day, Relax from sunset or the relax time (whichever comes first) and Night from the night time until the bright time. Lights still on Bright fade to Relax once in the evening.")
      (setting "mdi:white-balance-sunny" "Bright from" "input_datetime.lights_bright_from")
      (setting "mdi:weather-sunset-down" "Relax from (at the latest)" "input_datetime.lights_relax_from")
      (setting "mdi:weather-night" "Night from" "input_datetime.lights_night_from")
      (setting "mdi:weather-night" "Night mode" entities.nightMode)
    ])
    (section [
      (heading "mdi:window-shutter" "Shutters & window")
      (markdown "All shutters close fully at dusk and go to Privacy (top open, bottom blades at 35 %) once the sun is up, but not before the time below. Storm protection raises all blinds and closes the window on thunder, hail or wind above the threshold (Met.no mean wind, now or within 2 h), and blocks lowering them until it has been calm for 45 min.")
      (setting "mdi:window-shutter-open" "Open top shutters after" "input_datetime.shutters_open_after")
      (setting "mdi:weather-windy-variant" "Storm wind threshold" "input_number.storm_wind_threshold")
      (setting "mdi:weather-windy" "Storm protection active" "input_boolean.storm_protection")
      (setting "mdi:weather-lightning" "Last storm detected" "input_datetime.storm_last_detected")
    ])
    (section [
      (heading "mdi:robot-vacuum" "Roborock")
      (markdown "Cleans once a day after you have been away for 10 min (09:00-19:00), or at the fallback time if it has not run yet.")
      (setting "mdi:clock-outline" "Fallback time" "input_datetime.roborock_fallback_time")
      (roborock "mdi:eye-outline" "Sensors" "sensor")
      (roborock "mdi:brush" "Side brush" "side_brush")
      (roborock "mdi:brush-variant" "Main brush" "main_brush")
      (roborock "mdi:air-filter" "Filter" "filter")
      (roborock "mdi:filter-outline" "Dock strainer" "dock_strainer")
      (roborock "mdi:brush-outline" "Dock brush" "dock_maintenance_brush")
    ])
  ];
}
