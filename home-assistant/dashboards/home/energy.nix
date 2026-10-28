{ ... }:
let
  inherit (import ./cards.nix) section heading half;

  desktop = {
    power = "sensor.office_desktop_power";
    energy = "sensor.office_desktop_energy";
  };
  rack = {
    power = "sensor.living_room_server_rack_power";
    energy = "sensor.living_room_server_rack_energy";
  };

  # the desktop and the server rack, for the graphs
  both = key: [
    {
      entity = desktop.${key};
      name = "Desktop";
    }
    {
      entity = rack.${key};
      name = "Server rack";
    }
  ];
in
{
  title = "Energy";
  path = "energy";
  icon = "mdi:lightning-bolt-outline";
  type = "sections";
  max_columns = 2;
  sections = [
    (section [
      (heading "mdi:flash-outline" "Right now")
      (half {
        entity = desktop.power;
        icon = "mdi:desktop-tower-monitor";
        name = "Desktop";
      })
      (half {
        entity = rack.power;
        icon = "mdi:server";
        name = "Server rack";
      })
      (half {
        entity = "sensor.electricity_maps_co2_intensity";
        icon = "mdi:molecule-co2";
        name = "Grid CO₂";
      })
      (half {
        entity = "sensor.electricity_maps_grid_fossil_fuel_percentage";
        icon = "mdi:factory";
        name = "Grid from fossil fuels";
      })
      (heading "mdi:chart-line" "Last 24 hours")
      {
        type = "history-graph";
        entities = both "power";
        hours_to_show = 24;
        grid_options.columns = 12;
      }
    ])
    (section [
      (heading "mdi:chart-bar" "Last 14 days")
      {
        type = "statistics-graph";
        chart_type = "bar";
        days_to_show = 14;
        period = "day";
        stat_types = [ "change" ];
        unit = "kWh";
        entities = both "energy";
        grid_options.columns = 12;
      }
    ])
  ];
}
