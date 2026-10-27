{
  entities,
  ordered,
  jinjaList,
  template,
  call,
  notify,
  ...
}:
let
  # plugs that are only there to measure, they should never be off
  plugs = [
    entities.desktop
    entities.serverRack
  ];
in
{
  automation = [
    {
      id = "1791906314268";
      alias = "Energy: Keep Desktop and Server Rack Powered";
      description = "The Eve plugs are energy monitors only. If one ever reports off, switch it back on immediately and notify.";
      triggers = [
        {
          trigger = "state";
          entity_id = plugs;
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
            { off_plugs = "{{ ${jinjaList plugs} | select(\"is_state\", \"off\") | list }}"; }
          ];
        }
        (template "{{ off_plugs | count > 0 }}")
        (call "switch.turn_on" "{{ off_plugs }}")
        (notify {
          title = "Power restored";
          message = "{{ off_plugs | map(\"state_attr\", \"friendly_name\") | join(\" and \") }} was switched off and has been turned back on.";
          tag = "power-restored";
          interruptionLevel = "time-sensitive";
        })
      ];
      mode = "queued";
    }
  ];
}
