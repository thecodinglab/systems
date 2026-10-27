{
  entities,
  ordered,
  jinjaList,
  state,
  template,
  isHome,
  nightModeOff,
  call,
  ...
}:
let
  inherit (entities) lights officePresence;

  override = state "input_boolean.office_light_override" "off";
  entered = {
    trigger = "state";
    entity_id = officePresence;
    from = "off";
    to = "on";
  };

  # turned off while working, the bedroom only during the day
  otherRooms = [
    lights.kitchen
    lights.livingRoom
  ];
in
{
  automation = [
    {
      id = "1753172024868";
      alias = "Office: Light On When Occupied";
      description = "Turns the office lamp on when someone is at the desk and it is dark enough. Not while night mode is on. The stringlights are only turned on manually.";
      triggers = [ entered ];
      conditions = [
        override
        {
          condition = "numeric_state";
          entity_id = "sensor.office_presence_sensor_illuminance";
          below = 150;
        }
        nightModeOff
      ];
      actions = [ (call "light.turn_on" "light.office_lamp") ];
      mode = "single";
    }
    {
      id = "1753172088711";
      alias = "Office: Light Off When Vacant";
      description = "";
      triggers = [
        {
          trigger = "state";
          entity_id = officePresence;
          to = "off";
          for.minutes = 5;
        }
      ];
      conditions = [ override ];
      actions = [ (call "light.turn_off" lights.office) ];
      mode = "single";
    }
    {
      id = "1792500000009";
      alias = "Office: Turn Off Other Rooms While Working";
      description = "After 15 minutes of continuous presence in the office, turns off the kitchen and living room lights, and between 08:00 and 19:00 also the bedroom (unless the wake-up sunrise is running).";
      triggers = [
        {
          trigger = "state";
          entity_id = officePresence;
          to = "on";
          for.minutes = 15;
        }
      ];
      conditions = [
        isHome
        nightModeOff
      ];
      actions = [
        {
          variables = ordered [
            {
              bedroom_ok = ''
                {{ today_at('08:00') <= now() < today_at('19:00')
                   and is_state('${entities.scripts.sunrise}', 'off') }}'';
            }
            {
              targets = ''
                {{ (${jinjaList otherRooms}
                    + (['${lights.bedroom}'] if bedroom_ok else []))
                   | select('is_state', 'on') | list }}'';
            }
          ];
        }
        (template "{{ targets | count > 0 }}")
        (call "light.turn_off" "{{ targets }}" // { data.transition = 5; })
      ];
      mode = "single";
    }
    {
      id = "1792500000012";
      alias = "Office: Wake Desktop When Entering";
      description = "Sends Wake-on-LAN when someone enters the office and the desktop is asleep (plug below 60 W), between 06:00 and 23:00 and not in night mode.";
      triggers = [ entered ];
      conditions = [
        {
          condition = "time";
          after = "06:00:00";
          before = "23:00:00";
        }
        nightModeOff
        (state entities.desktop "on")
        {
          condition = "numeric_state";
          entity_id = "sensor.office_desktop_power";
          below = 60;
        }
      ];
      actions = [ (call "button.press" "button.office_desktop_wake_on_lan") ];
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
