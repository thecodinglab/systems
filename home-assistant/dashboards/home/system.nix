{ ... }:
let
  inherit (import ./cards.nix)
    section
    heading
    half
    full
    ;

  # a battery sensor of a device
  battery = name: entity: half { inherit entity name; };

  jetkvm = n: [
    (half {
      entity = "binary_sensor.living_room_jetkvm_${n}_online";
      icon = "mdi:monitor-shimmer";
      name = "JetKVM ${n}";
    })
    (half {
      entity = "sensor.living_room_jetkvm_${n}_temperature";
      name = "Temperature";
    })
  ];
in
{
  title = "System";
  path = "system";
  icon = "mdi:cog-outline";
  type = "sections";
  max_columns = 3;
  sections = [
    (section [
      (heading "mdi:home-assistant" "Home Assistant")
      (half {
        entity = "sensor.backup_last_successful_automatic_backup";
        icon = "mdi:backup-restore";
        name = "Last backup";
      })
      (half {
        entity = "sensor.backup_next_scheduled_automatic_backup";
        icon = "mdi:calendar-clock";
        name = "Next backup";
      })
      (full {
        entity = "binary_sensor.raspberry_pi_power_status";
        name = "Pi power supply";
      })
      {
        type = "entity-filter";
        card = {
          type = "entities";
          title = "Updates available";
        };
        conditions = [
          {
            condition = "state";
            state = "on";
          }
        ];
        show_empty = false;
        entities = [
          "update.home_assistant_core_update"
          "update.home_assistant_operating_system_update"
          "update.home_assistant_supervisor_update"
          "update.matter_server_update"
          "update.mosquitto_broker_update"
          "update.raspberry_pi_4_firmware"
          "update.living_room_aqara_hub_m3_firmware"
          "update.office_desktop_firmware"
          "update.living_room_server_rack_firmware"
          "update.living_room_jetkvm_1_firmware"
          "update.living_room_jetkvm_2_firmware"
        ];
        grid_options.columns = 12;
      }
    ])
    (section ([ (heading "mdi:monitor-shimmer" "KVMs") ] ++ jetkvm "1" ++ jetkvm "2"))
    (section [
      (heading "mdi:battery-outline" "Batteries")
      (battery "Kitchen dial" "sensor.kitchen_dial_switch_battery")
      (battery "Living room dial" "sensor.living_room_dial_switch_battery")
      (battery "Bedroom dial" "sensor.bedroom_dial_switch_battery")
      (battery "Kitchen climate" "sensor.kitchen_climate_battery")
      (battery "Bedroom climate" "sensor.bedroom_climate_battery")
      (battery "Bathroom climate" "sensor.bathroom_climate_battery")
      (battery "iPhone" "sensor.iphone_battery_level")
    ])
    (section [
      (heading "mdi:tune-variant" "Shutter calibration")
      {
        type = "custom:cover-time-based-card";
        grid_options.columns = 12;
      }
    ])
  ];
}
