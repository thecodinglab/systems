{
  entities,
  ordered,
  state,
  notState,
  template,
  call,
  notify,
  lightPreset,
  ...
}:
let
  inherit (entities) lights nightMode window;
in
{
  automation = [
    {
      id = "1792500000003";
      alias = "Night Mode: End in the Morning";
      description = "Turns night mode off at 05:00, before the earliest wake-up light starts.";
      triggers = [
        {
          trigger = "time";
          at = "05:00:00";
        }
      ];
      conditions = [ (state nightMode "on") ];
      actions = [ (call "input_boolean.turn_off" nightMode) ];
      mode = "single";
    }
  ];
  input_boolean = {
    night_mode = {
      icon = "mdi:weather-night";
      name = "Night Mode";
    };
  };
  script = {
    goodnight = {
      alias = "Goodnight";
      description = "Bedtime in one step: switches on night mode (keeps the office lamp from turning itself on until 05:00), turns off downstairs and the office, closes the living room window, turns the bedroom on with the evening preset if it is off (left as it is when called from the bedroom dial), and shows tomorrow's wake-up light with a button to skip it.";
      icon = "mdi:weather-night";
      mode = "single";
      fields = ordered [
        {
          from_bedroom = {
            name = "Called from the bedroom";
            description = "Leave the bedroom lights as they are instead of turning them on.";
            default = false;
            selector.boolean = null;
          };
        }
      ];
      sequence = [
        (call "input_boolean.turn_on" nightMode)
        (
          call "light.turn_off" [
            lights.kitchen
            lights.livingRoom
            lights.office
          ]
          // {
            data.transition = 3;
          }
        )
        {
          "if" = [
            (template "{{ not (from_bedroom | default(false)) }}")
            (state lights.bedroom "off")
          ];
          "then" = [
            (lightPreset {
              lights = lights.bedroom;
              preset = "auto";
              transition = 2;
            })
          ];
        }
        {
          "if" = [ (notState window "closed") ];
          "then" = [ (call "cover.close_cover" window) ];
        }
        {
          variables = ordered [
            { day = "{{ (now() + timedelta(days=0 if now().hour < 5 else 1)).strftime('%A') | lower }}"; }
            {
              scheduled = ''
                {{ is_state('input_boolean.bedroom_wake_up_light', 'on')
                   and is_state('input_boolean.bedroom_wake_up_' ~ day, 'on') }}'';
            }
            { skipped = "{{ is_state('input_boolean.bedroom_wake_up_skip_next', 'on') }}"; }
            { wake_time = "{{ states('input_datetime.bedroom_wake_up_' ~ day ~ '_time')[:5] }}"; }
          ];
        }
        {
          "if" = [ (template "{{ scheduled }}") ];
          "then" = [
            (notify {
              title = "Goodnight";
              message = ''
                {{ 'Wake-up light is skipped tomorrow.' if skipped
                   else 'Wake-up light tomorrow at ' ~ wake_time ~ '.' }}'';
              tag = "wake-up-tomorrow";
              actions = [
                {
                  action = "{{ 'WAKEUP_UNSKIP' if skipped else 'WAKEUP_SKIP_NEXT' }}";
                  title = "{{ 'Wake me after all' if skipped else 'Skip tomorrow' }}";
                }
              ];
            })
          ];
        }
      ];
    };
  };
}
