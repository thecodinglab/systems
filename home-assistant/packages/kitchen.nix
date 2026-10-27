{ entities, dialSwitch, ... }:
{
  automation = [
    (dialSwitch {
      id = "1791906312244";
      alias = "Kitchen: Dial Switch";
      description = "Hue tap dial. 1: toggle (time-of-day preset) / long: all lights off (20:00-05:00: Goodnight). 2: Bright. 3: Relax. 4: Night / long: room off. Rotary: dim (turns on if off).";
      device = entities.dialSwitches.kitchen;
      light = entities.lights.kitchen;
    })
  ];
}
