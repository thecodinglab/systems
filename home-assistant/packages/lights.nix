{
  entities,
  ordered,
  state,
  template,
  lightPreset,
  timeOfDay,
  ...
}:
let
  inherit (entities)
    lights
    datura
    twilight
    lightTimes
    lightPresets
    ;

  # sets <preset>_from to the time the preset starts, from its input_datetime
  # or the default
  starts =
    preset:
    "{%- set ${preset}_from = states('input_datetime.lights_${preset}_from') if has_value('input_datetime.lights_${preset}_from') else '${lightTimes.${preset}}' -%}";
in
{
  automation = [
    {
      id = "1792500000008";
      alias = "Lights: Shift to Relax in the Evening";
      description = "When evening starts (sunset or \"Lights Relax From\", whichever comes first), rooms that are still on the Bright preset fade to Relax over a minute (the bedroom to its own calmer Relax). Runs once per evening, so picking Bright again afterwards sticks.";
      triggers = [
        {
          trigger = "numeric_state";
          entity_id = "sun.sun";
          attribute = "elevation";
          below = 0;
        }
        {
          trigger = "time";
          at = "input_datetime.lights_relax_from";
        }
      ];
      conditions = [
        {
          condition = "time";
          after = "12:00:00";
        }
        (template ''
          {{ this.attributes.last_triggered is none
             or this.attributes.last_triggered < today_at('12:00') }}'')
        (state entities.scripts.sunrise "off")
        (template "{{ bright | count > 0 }}")
      ];
      actions = [
        (lightPreset {
          lights = "{{ bright }}";
          preset = "relax";
          transition = 60;
        })
      ];
      variables = ordered [
        {
          rooms = [
            datura.kitchen
            datura.livingRoom
            twilight.all
          ];
        }
        {
          bright = ''
            {%- set ns = namespace(l=[]) -%} {%- for room in rooms -%}
              {%- set on = room | select('is_state', 'on') | list -%}
              {%- set is_bright = on | select('is_state_attr', 'color_mode', 'color_temp')
                    | map('state_attr', 'brightness') | map('int', 0) | select('ge', 250) | list | count > 0
                  and on | map('state_attr', 'color_temp_kelvin') | map('int', 0) | select('ge', 2950) | list | count > 0 -%}
              {%- if is_bright -%}{%- set ns.l = ns.l + on -%}{%- endif -%}
            {%- endfor -%} {{ ns.l }}'';
        }
      ];
      mode = "single";
    }
  ];
  input_datetime = {
    lights_bright_from = timeOfDay {
      icon = "mdi:white-balance-sunny";
      initial = lightTimes.bright;
      name = "Lights Bright From";
    };
    lights_night_from = timeOfDay {
      icon = "mdi:weather-night";
      initial = lightTimes.night;
      name = "Lights Night From";
    };
    lights_relax_from = timeOfDay {
      icon = "mdi:weather-sunset-down";
      initial = lightTimes.relax;
      name = "Lights Relax From";
    };
  };
  script = {
    light_preset = {
      alias = "Light Preset";
      description = "Apply a light preset (Bright / Relax / Cozy / Night) to lights. 'auto' picks by time of day: Night between \"Lights Night From\" and \"Lights Bright From\", Relax from sunset or \"Lights Relax From\" (whichever is first), Bright otherwise. The bedroom Twilight lamps have their own calmer presets that lean on the indirect back light, and 'auto' there never picks Bright.";
      icon = "mdi:palette";
      mode = "parallel";
      fields = ordered [
        {
          lights = {
            name = "Lights";
            required = true;
            selector.entity = {
              domain = "light";
              multiple = true;
            };
          };
        }
        {
          preset = {
            name = "Preset";
            required = true;
            default = "auto";
            selector.select.options = [
              "auto"
              "bright"
              "relax"
              "cozy"
              "night"
            ];
          };
        }
        {
          transition = {
            name = "Transition";
            default = 0.4;
            selector.number = {
              min = 0;
              max = 3600;
              step = 0.1;
              unit_of_measurement = "s";
            };
          };
        }
      ];
      sequence = [
        {
          variables = ordered [
            { generic = lightPresets.generic; }
            { bedroom = lightPresets.bedroom; }
            { bedroom_members = twilight.all; }
            { requested = "{{ preset | default('auto') }}"; }
            {
              by_time = "{%- set t = now().strftime('%H:%M:%S') -%} ${starts "bright"} ${starts "relax"} ${starts "night"} {%- if t >= night_from or t < bright_from -%}night {%- elif t >= relax_from or (t >= '12:00:00' and state_attr('sun.sun', 'elevation') | float(90) < 0) -%}relax {%- else -%}bright {%- endif -%}";
            }
            {
              calls = ''
                {%- set ns = namespace(calls=[]) -%} {%- set ids = [lights] if lights is string else lights -%} {%- for e in ids -%}
                  {%- for light in (bedroom_members if e == '${lights.bedroom}' else [e]) -%}
                    {%- set p = by_time if requested == 'auto' else requested -%}
                    {%- if light in bedroom_members -%}
                      {%- set p = 'relax' if requested == 'auto' and p == 'bright' else p -%}
                      {%- set d = dict(bedroom['main' if light.endswith('_main') else 'ambiance'][p],
                                       transition=[transition | default(0.4) | float(0.4), 1.5] | max) -%}
                    {%- else -%}
                      {%- set d = dict(generic[p], transition=transition | default(0.4) | float(0.4)) -%}
                    {%- endif -%}
                    {%- set ns.calls = ns.calls + [{'entity_id': light, 'data': d}] -%}
                  {%- endfor -%}
                {%- endfor -%} {{ ns.calls }}'';
            }
          ];
        }
        {
          repeat = {
            for_each = "{{ calls }}";
            sequence = [
              {
                action = "light.turn_on";
                target.entity_id = "{{ repeat.item.entity_id }}";
                data = "{{ repeat.item.data }}";
              }
            ];
          };
        }
      ];
    };
  };
}
