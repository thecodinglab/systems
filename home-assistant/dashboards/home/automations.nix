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
      (heading "mdi:blinds" "Blinds & window")
      (markdown "The external venetian blinds are on the south-west façade, which gets direct sun from late morning (about 10:00 in winter, 12:00 in summer) until sunset. They go to Privacy (top up, bottom blades at 35 %) once the sun is up, but not before the time below, and close fully at dusk. On days forecast at or above the sun protection temperature they go to Shade while the sun is on the façade; in the cool season the sun is left in to warm the room. Storm protection raises all blinds and closes the window on gusts at or above the threshold (measured nearby, or forecast for the hour in progress), thunder or hail in that hour, or an official MeteoSwiss red wind warning or orange+ thunderstorm warning, and blocks lowering them until it has been calm for 45 min.")
      (setting "mdi:blinds-open" "Open top blinds after" "input_datetime.blinds_open_after")
      (setting "mdi:thermometer-high" "Sun protection from" "input_number.sun_protection_temperature")
      (setting "mdi:sun-angle-outline" "Sun on the blinds" "binary_sensor.living_room_sun_on_blinds")
      (setting "mdi:weather-windy-variant" "Storm gust threshold" "input_number.storm_gust_threshold")
      (setting "mdi:weather-windy" "Storm protection active" "input_boolean.storm_protection")
      (setting "mdi:weather-lightning" "Last storm detected" "input_datetime.storm_last_detected")
    ])
    (section [
      (heading "mdi:radiator" "Heating & airing")
      (markdown "In the heating period (below 15 °C outside) the living room window opens fully for 5-10 min at each airing time while you are home or were home within the last 48 h, unless it rains, storm protection is on or the window was just open. **Air now** opens it whatever the weather. A room averaging below 19 °C over 3 days sends a prepared email to Wincasa.")
      (setting "mdi:window-open-variant" "Automatic airing" "automation.heating_airing_reminder")
      (setting "mdi:play" "Air now" "script.airing")
      (setting "mdi:weather-sunset-up" "Morning" "input_datetime.airing_time_morning")
      (setting "mdi:white-balance-sunny" "Midday" "input_datetime.airing_time_midday")
      (setting "mdi:weather-sunset-down" "Evening" "input_datetime.airing_time_evening")
      (setting "mdi:bed-outline" "Bedroom, 3 day mean" "sensor.bedroom_temperature_3_day_mean")
      (setting "mdi:countertop-outline" "Kitchen, 3 day mean" "sensor.kitchen_temperature_3_day_mean")
    ])
    (section [
      (heading "mdi:robot-vacuum" "Roborock")
      (markdown "Cleans downstairs once a day after you have been away for 10 min (09:00-19:00), or at the fallback time if it has not run yet. Mops on Mondays and Thursdays, vacuums only on the other days. **Upstairs** on the home view washes the mop, then guides you through carrying it up and back down, and empties the dustbin and washes the mop once it is on the dock again.")
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
