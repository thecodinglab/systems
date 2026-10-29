# the landlord's (Wincasa) advice for the heating period: air 2-4 times a day
# for 5-10 minutes with the windows fully open instead of leaving them tilted
# (done with the living room window), and report rooms that stay well below
# 20-21 °C for several days
{
  entities,
  ordered,
  jinjaList,
  wet,
  isHome,
  nightModeOff,
  notState,
  template,
  call,
  notify,
  hourlyForecast,
  forecastHours,
  timeOfDay,
  ...
}:
let
  inherit (entities) weather window;

  stormProtection = "input_boolean.storm_protection";
  airing = entities.scripts.airing;

  # the floor heating follows the outside temperature, below this (mean over
  # the next 24 h) it is heating period
  heatingLimit = 15;

  # "well below" the usual 20-21 °C (19-20 °C in Minergie buildings)
  minimum = 19;

  # Stosslüften, shorter the colder it is
  airingMinutes = "{{ 5 if state_attr('${weather}', 'temperature') | float(10) < 5 else 10 }}";

  # the rooms whose temperature is watched, `de` for the mail to Wincasa
  rooms = [
    {
      id = "bedroom";
      name = "Bedroom";
      de = "Schlafzimmer";
    }
    {
      id = "kitchen";
      name = "Kitchen";
      de = "Küche";
    }
  ];
  mean = room: "sensor.${room.id}_temperature_3_day_mean";
in
{
  automation = [
    {
      id = "1792500000015";
      alias = "Heating: Air the Living Room";
      description = "In the heating period (Met.no mean below ${toString heatingLimit} °C over the next 24 h) airs the living room at the three airing times: opens the window fully for 5 minutes below 5 °C outside, 10 otherwise, then closes it (script.airing). Skipped while away, in night mode, when it rains or storm protection is on and while the window is open or was closed less than an hour ago (just aired).";
      triggers =
        map
          (n: {
            trigger = "time";
            at = "input_datetime.airing_time_${n}";
          })
          [
            "morning"
            "midday"
            "evening"
          ];
      conditions = [
        isHome
        nightModeOff
        (
          template "{{ is_state('${window}', 'closed') and now() - states.${window}.last_changed > timedelta(hours=1) }}"
          // {
            alias = "Living room window closed for an hour (not just aired)";
          }
        )
      ];
      actions = [
        hourlyForecast
        {
          variables = ordered [
            { t_out = "{{ state_attr('${weather}', 'temperature') | float(10) }}"; }
            { upcoming = forecastHours 24; }
            {
              t_mean = "{{ (upcoming | map(attribute='temperature', default=t_out) | map('float', t_out) | list + [t_out]) | average }}";
            }
          ];
        }
        (template "{{ t_mean < ${toString heatingLimit} }}")
        { action = airing; }
      ];
      mode = "single";
    }
    {
      id = "1792500000016";
      alias = "Heating: Rooms Too Cold";
      description = "Every evening: when the bedroom or kitchen has averaged below ${toString minimum} °C over the last 3 days, sends the averages with a button for a prepared email to Wincasa, who ask to be told when it stays well below 20-21 °C for several days. At most every 3 days.";
      triggers = [
        {
          trigger = "time";
          at = "19:00:00";
        }
      ];
      conditions = [
        (template "{{ cold | count > 0 }}")
        (template ''
          {{ this.attributes.last_triggered is none
             or now() - this.attributes.last_triggered > timedelta(days=3, minutes=-10) }}'')
      ];
      actions = [
        {
          variables = ordered [
            {
              body = ''
                Guten Tag

                Die Raumtemperatur in meiner Wohnung liegt seit mehreren Tagen deutlich unter der üblichen Temperatur von 20 bis 21 °C. Durchschnitt der letzten 3 Tage:
                {%- for r in cold %}
                - {{ r.de }}: {{ r.mean }} °C (aktuell {{ r.now }} °C)
                {%- endfor %}

                Freundliche Grüsse
                {{ state_attr('${entities.person}', 'friendly_name') }}'';
            }
          ];
        }
        (notify {
          title = "Rooms too cold";
          message = "{% for r in cold %}{{ r.name }}: {{ r.mean }} °C on average over 3 days (now {{ r.now }} °C)\n{% endfor %}Wincasa asks to be told when it stays this cold: Wincasa Home, info@wincasa.ch or by phone.";
          tag = "rooms-too-cold";
          actions = [
            {
              action = "URI";
              title = "Email Wincasa";
              uri = "mailto:info@wincasa.ch?subject={{ 'Raumtemperatur zu tief' | urlencode }}&body={{ body | urlencode }}";
            }
          ];
        })
      ];
      variables = ordered [
        {
          rooms = map (room: {
            inherit (room) name de;
            mean = mean room;
            now = "sensor.${room.id}_climate_temperature";
          }) rooms;
        }
        {
          # only with (almost) 3 full days of data
          cold = ''
            {% set ns = namespace(cold=[]) %}
            {%- for r in rooms -%}
              {%- set m = states(r.mean) -%}
              {%- if m | is_number and m | float < ${toString minimum} and state_attr(r.mean, 'age_coverage_ratio') | float(0) >= 0.9 -%}
                {%- set ns.cold = ns.cold + [{'name': r.name, 'de': r.de, 'mean': m | float | round(1), 'now': states(r.now) | float(0) | round(1)}] -%}
              {%- endif -%}
            {%- endfor -%}
            {{ ns.cold }}'';
        }
      ];
      mode = "single";
    }
  ];
  input_datetime = {
    airing_time_morning = timeOfDay {
      icon = "mdi:weather-sunset-up";
      initial = "07:30:00";
      name = "Airing Time Morning";
    };
    airing_time_midday = timeOfDay {
      icon = "mdi:white-balance-sunny";
      initial = "12:30:00";
      name = "Airing Time Midday";
    };
    airing_time_evening = timeOfDay {
      icon = "mdi:weather-sunset-down";
      initial = "18:30:00";
      name = "Airing Time Evening";
    };
  };
  # time weighted mean over 3 days, loaded from the recorder after a restart;
  # the buffer holds far more than 3 days of the climate sensors' readings
  sensor = map (room: {
    platform = "statistics";
    name = "${room.name} Temperature 3 Day Mean";
    unique_id = "${room.id}_temperature_3_day_mean";
    entity_id = "sensor.${room.id}_climate_temperature";
    state_characteristic = "average_linear";
    max_age.hours = 72;
    sampling_size = 10000;
    precision = 1;
  }) rooms;
  script = {
    airing = {
      alias = "Airing";
      description = "Stosslüften with the living room window: opens it fully for 5 minutes (below 5 °C outside) or 10 minutes, then closes it again (earlier if you close it yourself). Does nothing while it rains or storm protection is on.";
      icon = "mdi:window-open-variant";
      mode = "single";
      max_exceeded = "silent";
      sequence = [
        { variables = ordered [ { minutes = airingMinutes; } ]; }
        (
          template "{{ not is_state('${weather}', ${jinjaList wet}) and is_state('${stormProtection}', 'off') }}"
          // {
            alias = "No rain and no storm protection";
          }
        )
        (call "cover.open_cover" window)
        {
          wait_for_trigger = [
            {
              trigger = "state";
              entity_id = window;
              to = "closed";
            }
          ];
          timeout.minutes = "{{ minutes }}";
          continue_on_timeout = true;
        }
        {
          "if" = [ (notState window "closed") ];
          "then" = [ (call "cover.close_cover" window) ];
        }
      ];
    };
  };
}
