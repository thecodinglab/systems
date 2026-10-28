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

  # what script.light_preset sets per preset, the dashboard uses them to tell
  # which preset a room is on. The bedroom Twilight lamps have their own calmer
  # ones for the main (down) and ambiance (back) lights
  lightPresets = {
    generic = {
      bright = {
        brightness_pct = 100;
        color_temp_kelvin = 3000;
      };
      relax = {
        brightness_pct = 60;
        color_temp_kelvin = 2700;
      };
      cozy = {
        brightness_pct = 30;
        color_temp_kelvin = 2200;
      };
      night = {
        brightness_pct = 10;
        color_temp_kelvin = 2200;
      };
    };
    bedroom = {
      main = {
        bright = {
          brightness_pct = 100;
          color_temp_kelvin = 3000;
          effect = "off";
        };
        relax = {
          brightness_pct = 40;
          color_temp_kelvin = 2700;
          effect = "off";
        };
        cozy = {
          brightness_pct = 15;
          color_temp_kelvin = 2200;
          effect = "off";
        };
        night = {
          brightness_pct = 3;
          color_temp_kelvin = 2000;
          effect = "off";
        };
      };
      ambiance = {
        bright = {
          brightness_pct = 70;
          color_temp_kelvin = 2700;
          effect = "off";
        };
        relax = {
          brightness_pct = 70;
          color_temp_kelvin = 2400;
          effect = "off";
        };
        cozy = {
          brightness_pct = 55;
          xy_color = [
            0.555
            0.408
          ];
          effect = "candle";
        };
        night = {
          brightness_pct = 8;
          xy_color = [
            0.575
            0.395
          ];
          effect = "off";
        };
      };
    };
  };

  # the living room shutter layouts of script.shutter_preset, 100 is fully open
  # for both the position and the blades
  shutterPresets =
    let
      pair = position: tilt: { inherit position tilt; };
    in
    {
      privacy = {
        top = pair 100 100;
        bottom = pair 0 35;
      };
      open = {
        top = pair 100 100;
        bottom = pair 100 100;
      };
      shade = {
        top = pair 0 50;
        bottom = pair 0 50;
      };
      closed = {
        top = pair 0 0;
        bottom = pair 0 0;
      };
      night = {
        top = pair 0 0;
        bottom = pair 0 35;
      };
    };
}
