# building blocks shared by the views
rec {
  section = cards: {
    type = "grid";
    inherit cards;
  };

  heading = icon: title: {
    type = "heading";
    heading = title;
    heading_style = "title";
    inherit icon;
  };

  markdown = content: {
    type = "markdown";
    text_only = true;
    inherit content;
  };

  # a tile that is columns wide out of 12
  tile =
    columns: attrs:
    {
      type = "tile";
      grid_options = { inherit columns; };
    }
    // attrs;
  half = tile 6;
  full = tile 12;

  # tapping the tile or its icon does the same
  onTap = action: {
    tap_action = action;
    icon_tap_action = action;
  };

  performAction =
    perform_action: extra:
    {
      action = "perform-action";
      inherit perform_action;
    }
    // extra;

  stateIs = entity: state: {
    condition = "state";
    inherit entity state;
  };
}
