{ entities, navigate, ... }:
let
  inherit (import ./cards.nix)
    section
    heading
    markdown
    half
    full
    onTap
    performAction
    ;
  inherit (entities) scripts shutters;

  shutter =
    name: entity:
    half {
      inherit entity name;
      features = [
        { type = "cover-position"; }
        { type = "cover-tilt-position"; }
      ];
    };

  preset =
    name: icon: key:
    half (
      {
        entity = scripts.shutterPreset;
        inherit name icon;
        hide_state = true;
      }
      // onTap (performAction scripts.shutterPreset { data.preset = key; })
    );

  resetScript = "script.shutter_reset";
in
{
  title = "Shutters";
  path = "shutters";
  icon = "mdi:window-shutter";
  type = "sections";
  max_columns = 2;
  subview = true;
  back_path = navigate "home";
  sections = [
    (section [
      (heading "mdi:window-shutter" "Shutters")
      (shutter "Top left" (builtins.elemAt shutters.top 0))
      (shutter "Top right" (builtins.elemAt shutters.top 1))
      (shutter "Bottom left" (builtins.elemAt shutters.bottom 0))
      (shutter "Bottom right" (builtins.elemAt shutters.bottom 1))
      (preset "Open" "mdi:window-shutter-open" "open")
      (preset "Shade" "mdi:sun-angle-outline" "shade")
      (preset "Privacy" "mdi:eye-off-outline" "privacy")
      (preset "Closed" "mdi:window-shutter" "closed")
      (heading "mdi:window-open-variant" "Window")
      (full {
        entity = entities.window;
        name = "Window";
        features = [ { type = "cover-position"; } ];
        features_position = "inline";
      })
    ])
    (section [
      (heading "mdi:tune-variant" "Calibration")
      (markdown "Positions are estimated from travel time. If a shutter drifts out of sync, reset them all: they close fully and start counting from zero.")
      (full (
        {
          entity = resetScript;
          name = "Reset shutters";
          icon = "mdi:restore";
          hide_state = true;
        }
        // onTap (performAction "script.turn_on" { target.entity_id = resetScript; })
      ))
    ])
  ];
}
