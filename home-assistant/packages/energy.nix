{ ordered }:
{
  automation = [
    {
      id = "1791906314268";
      alias = "Energy: Keep Desktop and Server Rack Powered";
      description = "The Eve plugs are energy monitors only. If one ever reports off, switch it back on immediately and notify.";
      triggers = [
        {
          trigger = "state";
          entity_id = [
            "switch.office_desktop"
            "switch.living_room_server_rack"
          ];
          to = "off";
        }
        {
          trigger = "homeassistant";
          event = "start";
        }
      ];
      actions = [
        {
          variables = ordered [
            {
              off_plugs = "{{ [\"switch.office_desktop\", \"switch.living_room_server_rack\"] | select(\"is_state\", \"off\") | list }}";
            }
          ];
        }
        {
          condition = "template";
          value_template = "{{ off_plugs | count > 0 }}";
        }
        {
          action = "switch.turn_on";
          target = {
            entity_id = "{{ off_plugs }}";
          };
        }
        {
          action = "notify.mobile_app_florians_iphone_18";
          data = {
            title = "Power restored";
            message = "{{ off_plugs | map(\"state_attr\", \"friendly_name\") | join(\" and \") }} was switched off and has been turned back on.";
            data = {
              tag = "power-restored";
              push = {
                interruption-level = "time-sensitive";
              };
            };
          };
        }
      ];
      mode = "queued";
    }
  ];
}
