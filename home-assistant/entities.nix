# entity ids that are used by more than one automation or package, renaming a
# device in home assistant only needs a change here
rec {
  phone = "notify.mobile_app_florians_iphone_18";
  person = "person.florian";
  nightMode = "input_boolean.night_mode";
  weather = "weather.forecast_home";

  # light groups, one per room
  lights = {
    kitchen = "light.kitchen_lights";
    livingRoom = "light.living_room_lights";
    bedroom = "light.bedroom_lights";
    office = "light.office_lights";
  };
  allLights = with lights; [
    kitchen
    livingRoom
    bedroom
    office
  ];

  datura = {
    kitchen = [
      "light.kitchen_datura_top"
      "light.kitchen_datura_bottom"
    ];
    livingRoom = [
      "light.living_room_datura_top"
      "light.living_room_datura_bottom"
    ];
  };

  # the two bedside lamps, each a main (down) and an ambiance (back) light;
  # light.bedroom_lights groups all four
  twilight = rec {
    left = {
      main = "light.bedroom_twilight_left_main";
      ambiance = "light.bedroom_twilight_left_ambiance";
    };
    right = {
      main = "light.bedroom_twilight_right_main";
      ambiance = "light.bedroom_twilight_right_ambiance";
    };
    main = [
      left.main
      right.main
    ];
    ambiance = [
      left.ambiance
      right.ambiance
    ];
    all = [
      left.main
      left.ambiance
      right.main
      right.ambiance
    ];
  };

  # hue tap dials, see dialSwitch in lib.nix
  dialSwitches = {
    kitchen = "event.kitchen_dial_switch";
    livingRoom = "event.living_room_dial_switch";
    bedroom = "event.bedroom_dial_switch";
  };

  window = "cover.living_room_window";
  shutters = rec {
    top = [
      "cover.living_room_shutter_top_left"
      "cover.living_room_shutter_top_right"
    ];
    bottom = [
      "cover.living_room_shutter_bottom_left"
      "cover.living_room_shutter_bottom_right"
    ];
    all = top ++ bottom;
  };

  officePresence = "binary_sensor.office_presence_sensor_occupancy";
  desktop = "switch.office_desktop";
  serverRack = "switch.living_room_server_rack";
  vacuum = "vacuum.living_room_roborock";

  scripts = {
    goodnight = "script.goodnight";
    lightPreset = "script.light_preset";
    shutterPreset = "script.shutter_preset";
    sunrise = "script.bedroom_sunrise";
  };

  # defaults of the lights_*_from helpers, also the fallback while they have
  # no value
  lightTimes = {
    bright = "06:00:00";
    relax = "20:00:00";
    night = "22:30:00";
  };
}
