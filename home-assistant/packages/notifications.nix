{ ordered }:
{
  automation = [
    {
      id = "1791911061283";
      alias = "Battery: Notify When Low";
      description = "Daily check of all battery-powered devices (except the iPhone and the Roborock, which recharge themselves). Sends one summary while any battery is below 20%.";
      triggers = [
        {
          trigger = "time";
          at = "18:07:00";
        }
      ];
      conditions = [
        {
          condition = "template";
          value_template = "{{ low | count > 0 }}";
        }
      ];
      actions = [
        {
          action = "notify.mobile_app_florians_iphone_18";
          data = {
            title = "Low battery";
            message = "{{ low | join(\"\\n\") }}";
            data = {
              tag = "low-battery";
            };
          };
        }
      ];
      mode = "single";
      variables = ordered [
        { threshold = 20; }
        {
          low = "{% set ns = namespace(low=[]) %}{% for s in states.sensor | selectattr(\"attributes.device_class\", \"defined\") | selectattr(\"attributes.device_class\", \"eq\", \"battery\") %}{% if not (s.entity_id is search(\"iphone|roborock\")) and s.state | is_number and s.state | float < threshold %}{% set ns.low = ns.low + [(area_name(s.entity_id) ~ \" \" ~ device_name(s.entity_id)) | trim ~ \": \" ~ s.state | int ~ \"%\"] %}{% endif %}{% endfor %}{% for s in states.binary_sensor | selectattr(\"attributes.device_class\", \"defined\") | selectattr(\"attributes.device_class\", \"eq\", \"battery\") | selectattr(\"state\", \"eq\", \"on\") %}{% set ns.low = ns.low + [(area_name(s.entity_id) ~ \" \" ~ device_name(s.entity_id)) | trim ~ \": low\"] %}{% endfor %}{{ ns.low }}";
        }
      ];
    }
    {
      id = "1792500000007";
      alias = "Notifications: Handle Actions";
      description = "Handles the buttons on actionable notifications: close the window, skip or un-skip tomorrow's wake-up light, raise the blinds / shutters to Privacy, send the Roborock to the dock and reset Roborock consumables.";
      triggers = [
        {
          trigger = "event";
          event_type = "mobile_app_notification_action";
        }
      ];
      conditions = [
        {
          condition = "template";
          value_template = ''
            {{ action in ['CLOSE_WINDOW', 'WAKEUP_SKIP_NEXT', 'WAKEUP_UNSKIP', 'SHUTTERS_RAISE', 'SHUTTERS_PRIVACY', 'SHUTTERS_NIGHT', 'ROBOROCK_DOCK']
               or action.startswith('ROBOROCK_RESET:') }}'';
        }
      ];
      actions = [
        {
          choose = [
            {
              conditions = "{{ action == 'CLOSE_WINDOW' }}";
              sequence = [
                {
                  action = "cover.close_cover";
                  target = {
                    entity_id = "cover.living_room_window";
                  };
                }
              ];
            }
            {
              conditions = "{{ action == 'WAKEUP_SKIP_NEXT' }}";
              sequence = [
                {
                  action = "input_boolean.turn_on";
                  target = {
                    entity_id = "input_boolean.bedroom_wake_up_skip_next";
                  };
                }
              ];
            }
            {
              conditions = "{{ action == 'WAKEUP_UNSKIP' }}";
              sequence = [
                {
                  action = "input_boolean.turn_off";
                  target = {
                    entity_id = "input_boolean.bedroom_wake_up_skip_next";
                  };
                }
              ];
            }
            {
              conditions = "{{ action == 'SHUTTERS_RAISE' }}";
              sequence = [
                {
                  action = "script.turn_on";
                  target = {
                    entity_id = "script.shutter_preset";
                  };
                  data = {
                    variables = ordered [ { preset = "open"; } ];
                  };
                }
              ];
            }
            {
              conditions = "{{ action == 'SHUTTERS_PRIVACY' }}";
              sequence = [
                {
                  action = "script.turn_on";
                  target = {
                    entity_id = "script.shutter_preset";
                  };
                  data = {
                    variables = ordered [ { preset = "privacy"; } ];
                  };
                }
              ];
            }
            {
              conditions = "{{ action == 'SHUTTERS_NIGHT' }}";
              sequence = [
                {
                  action = "script.turn_on";
                  target = {
                    entity_id = "script.shutter_preset";
                  };
                  data = {
                    variables = ordered [ { preset = "night"; } ];
                  };
                }
              ];
            }
            {
              conditions = "{{ action == 'ROBOROCK_DOCK' }}";
              sequence = [
                {
                  action = "vacuum.return_to_base";
                  target = {
                    entity_id = "vacuum.living_room_roborock";
                  };
                }
              ];
            }
            {
              conditions = "{{ action.startswith('ROBOROCK_RESET:') }}";
              sequence = [
                {
                  action = "button.press";
                  target = {
                    entity_id = "{{ action.split(':')[1] }}";
                  };
                }
              ];
            }
          ];
        }
      ];
      variables = ordered [ { action = "{{ trigger.event.data.action | default('') }}"; } ];
      mode = "queued";
      max = 10;
    }
    {
      id = "1792500000013";
      alias = "System: Health Alerts";
      description = "Notifies when an important device has been offline for 30 minutes (and clears it when it is back), when an automatic backup fails or none succeeded for 2 days, and when the Raspberry Pi reports a power problem.";
      triggers = [
        {
          trigger = "state";
          entity_id = [
            "light.kitchen_datura_top"
            "light.kitchen_datura_bottom"
            "light.living_room_datura_top"
            "light.living_room_datura_bottom"
            "light.bedroom_twilight_left_main"
            "light.bedroom_twilight_right_main"
            "light.office_lamp"
            "sensor.kitchen_climate_temperature"
            "sensor.bedroom_climate_temperature"
            "sensor.bathroom_climate_temperature"
            "binary_sensor.office_presence_sensor_occupancy"
            "event.kitchen_dial_switch_button_1"
            "event.living_room_dial_switch_button_1"
            "event.bedroom_dial_switch_button_1"
            "light.living_room_window_open_relay"
            "light.living_room_shutter_top_left_up_relay"
            "light.living_room_shutter_top_right_up_relay"
            "light.living_room_shutter_bottom_left_up_relay"
            "light.living_room_shutter_bottom_right_up_relay"
            "switch.office_desktop"
            "switch.living_room_server_rack"
          ];
          to = "unavailable";
          for = {
            minutes = 30;
          };
          id = "offline";
        }
        {
          trigger = "state";
          entity_id = [
            "light.kitchen_datura_top"
            "light.kitchen_datura_bottom"
            "light.living_room_datura_top"
            "light.living_room_datura_bottom"
            "light.bedroom_twilight_left_main"
            "light.bedroom_twilight_right_main"
            "light.office_lamp"
            "sensor.kitchen_climate_temperature"
            "sensor.bedroom_climate_temperature"
            "sensor.bathroom_climate_temperature"
            "binary_sensor.office_presence_sensor_occupancy"
            "event.kitchen_dial_switch_button_1"
            "event.living_room_dial_switch_button_1"
            "event.bedroom_dial_switch_button_1"
            "light.living_room_window_open_relay"
            "light.living_room_shutter_top_left_up_relay"
            "light.living_room_shutter_top_right_up_relay"
            "light.living_room_shutter_bottom_left_up_relay"
            "light.living_room_shutter_bottom_right_up_relay"
            "switch.office_desktop"
            "switch.living_room_server_rack"
          ];
          from = "unavailable";
          id = "back";
        }
        {
          trigger = "state";
          entity_id = "event.backup_automatic_backup";
          attribute = "event_type";
          to = "failed";
          id = "backup_failed";
        }
        {
          trigger = "time";
          at = "09:00:00";
          id = "backup_check";
        }
        {
          trigger = "state";
          entity_id = "binary_sensor.raspberry_pi_power_status";
          to = "on";
          id = "power";
        }
      ];
      actions = [
        {
          choose = [
            {
              conditions = [
                {
                  condition = "trigger";
                  id = "offline";
                }
              ];
              sequence = [
                {
                  action = "notify.mobile_app_florians_iphone_18";
                  data = {
                    title = "Device offline";
                    message = "{{ name }} ({{ area_name(trigger.entity_id) or 'no area' }}) has been offline for 30 minutes.";
                    data = {
                      tag = "{{ tag }}";
                    };
                  };
                }
              ];
            }
            {
              conditions = [
                {
                  condition = "trigger";
                  id = "back";
                }
              ];
              sequence = [
                {
                  action = "notify.mobile_app_florians_iphone_18";
                  data = {
                    message = "clear_notification";
                    data = {
                      tag = "{{ tag }}";
                    };
                  };
                }
              ];
            }
            {
              conditions = [
                {
                  condition = "trigger";
                  id = "backup_failed";
                }
              ];
              sequence = [
                {
                  action = "notify.mobile_app_florians_iphone_18";
                  data = {
                    title = "Backup failed";
                    message = "The automatic backup failed: {{ state_attr('event.backup_automatic_backup', 'failed_reason') or 'unknown reason' }}.";
                    data = {
                      tag = "backup";
                    };
                  };
                }
              ];
            }
            {
              conditions = [
                {
                  condition = "trigger";
                  id = "backup_check";
                }
                {
                  condition = "template";
                  value_template = "{% set last = states('sensor.backup_last_successful_automatic_backup') | as_datetime(none) %} {{ last is none or now() - last > timedelta(days=2) }}";
                }
              ];
              sequence = [
                {
                  action = "notify.mobile_app_florians_iphone_18";
                  data = {
                    title = "Backup overdue";
                    message = "No automatic backup has succeeded in the last 2 days.";
                    data = {
                      tag = "backup";
                    };
                  };
                }
              ];
            }
            {
              conditions = [
                {
                  condition = "trigger";
                  id = "power";
                }
              ];
              sequence = [
                {
                  action = "notify.mobile_app_florians_iphone_18";
                  data = {
                    title = "Raspberry Pi power";
                    message = "The Raspberry Pi reports under-voltage. Check its power supply.";
                    data = {
                      tag = "rpi-power";
                    };
                  };
                }
              ];
            }
          ];
        }
      ];
      variables = ordered [
        {
          name = ''
            {{ (device_name(trigger.entity_id) or state_attr(trigger.entity_id, 'friendly_name') or trigger.entity_id)
               if trigger.entity_id | default(none) else ''' }}'';
        }
        { tag = "{{ 'offline-' ~ trigger.entity_id if trigger.entity_id | default(none) else 'system' }}"; }
      ];
      mode = "queued";
      max = 20;
    }
  ];
}
