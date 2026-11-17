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
  inherit (entities) scripts blinds;

  blind =
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
        entity = scripts.blindPreset;
        inherit name icon;
        hide_state = true;
      }
      // onTap (performAction scripts.blindPreset { data.preset = key; })
    );

  resetScript = "script.blind_reset";
in
{
  title = "Blinds";
  path = "blinds";
  icon = "mdi:blinds";
  type = "sections";
  max_columns = 2;
  subview = true;
  back_path = navigate "home";
  sections = [
    (section [
      (heading "mdi:blinds" "Blinds")
      (blind "Top left" (builtins.elemAt blinds.top 0))
      (blind "Top right" (builtins.elemAt blinds.top 1))
      (blind "Bottom left" (builtins.elemAt blinds.bottom 0))
      (blind "Bottom right" (builtins.elemAt blinds.bottom 1))
      (preset "Open" "mdi:blinds-open" "open")
      (preset "Shade" "mdi:sun-angle-outline" "shade")
      (preset "Privacy" "mdi:eye-off-outline" "privacy")
      (preset "Closed" "mdi:blinds" "closed")
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
      (markdown "Positions are estimated from travel time. If a blind drifts out of sync, reset them all: they close fully and start counting from zero.")
      (full (
        {
          entity = resetScript;
          name = "Reset blinds";
          icon = "mdi:restore";
          hide_state = true;
        }
        // onTap (performAction "script.turn_on" { target.entity_id = resetScript; })
      ))
    ])
  ];
}
