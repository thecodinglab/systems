{ entities, lib, ... }:
let
  inherit (import ./cards.nix)
    section
    heading
    markdown
    half
    full
    onTap
    performAction
    stateIs
    ;

  enabled = "input_boolean.bedroom_wake_up_light";

  days = [
    "Monday"
    "Tuesday"
    "Wednesday"
    "Thursday"
    "Friday"
    "Saturday"
    "Sunday"
  ];

  # per day: the time while the schedule is active, the same greyed out while
  # it is paused, and a plain toggle while the day is skipped
  dayTiles =
    day:
    let
      id = lib.toLower day;
      on = "input_boolean.bedroom_wake_up_${id}";
      time =
        color: light:
        half {
          inherit color;
          name = day;
          entity = "input_datetime.bedroom_wake_up_${id}_time";
          icon = "mdi:alarm";
          tap_action.action = "more-info";
          icon_tap_action = performAction "input_boolean.turn_off" { target.entity_id = on; };
          visibility = [
            (stateIs on "on")
            (stateIs enabled light)
          ];
        };
    in
    [
      (time "orange" "on")
      (time "grey" "off")
      (half (
        {
          name = day;
          entity = on;
          icon = "mdi:alarm-off";
          hide_state = false;
          state_content = [ ];
          visibility = [ (stateIs on "off") ];
        }
        // onTap { action = "toggle"; }
      ))
    ];

  toggle =
    attrs:
    full (
      {
        features = [ { type = "toggle"; } ];
        features_position = "inline";
      }
      // attrs
    );
in
{
  title = "Wake-up";
  path = "wake-up";
  icon = "mdi:weather-sunset-up";
  type = "sections";
  max_columns = 2;
  sections = [
    (section [
      (heading "mdi:weather-sunset-up" "Wake-up light")
      (markdown "The bedroom lights fade in over 30 minutes, finishing at the time you set. It only runs when you're home and the bedroom lights are off. Pressing any bedroom button or turning the lights off stops it.")
      (toggle {
        color = "orange";
        entity = enabled;
        icon = "mdi:weather-sunset-up";
        name = "Wake-up light";
      })
      (full (
        {
          color = "orange";
          entity = entities.scripts.sunrise;
          icon = "mdi:play";
          name = "Try a sunrise now";
          hide_state = true;
        }
        // onTap (performAction "script.toggle" { target.entity_id = entities.scripts.sunrise; })
      ))
      (toggle {
        entity = "input_boolean.bedroom_wake_up_skip_next";
        icon = "mdi:alarm-off";
        name = "Skip next wake-up";
      })
    ])
    (section (
      [
        (heading "mdi:calendar-clock" "Schedule" // { visibility = [ (stateIs enabled "on") ]; })
        (heading "mdi:calendar-clock" "Schedule (paused)" // { visibility = [ (stateIs enabled "off") ]; })
        (markdown "Tap a day to change its time. Tap the icon to skip or include it.")
      ]
      ++ lib.concatMap dayTiles days
    ))
  ];
}
