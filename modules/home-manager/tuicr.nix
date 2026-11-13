{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.custom.tuicr;
  palette = import ./theme/palette.nix;
  toml = pkgs.formats.toml { };

  # a step of `amount` from one hex colour toward another, the same blend the
  # neovim colours lay their diff grounds with
  mix =
    from: to: amount:
    lib.concatMapStrings
      (
        i:
        let
          channel = hex: lib.fromHexString (builtins.substring i 2 hex);
          a = channel from;
          value = builtins.floor (a + (channel to - a) * amount + 0.5);
        in
        lib.fixedWidthString 2 "0" (lib.toLower (lib.toHexString value))
      )
      [
        0
        2
        4
      ];

  # The syntax colours as the neovim colours have them: what you wrote in the
  # ink, comments and punctuation in the grey, operators a step toward it,
  # keywords purple, functions blue, types cyan, strings green, numbers and
  # constants amber, builtins the strong ink.
  syntaxTheme =
    appearance: p:
    let
      rule = scope: settings: {
        inherit scope;
        settings = lib.mapAttrs (key: value: if key == "fontStyle" then value else "#${value}") settings;
      };
    in
    pkgs.writeText "system-${appearance}.tmTheme" (
      lib.generators.toPlist { escape = true; } {
        name = "system-${appearance}";
        settings = [
          {
            settings = {
              foreground = "#${p.base05}";
              background = "#${p.base00}";
              caret = "#${p.base05}";
              selection = "#${palette.selection.${appearance}}";
              lineHighlight = "#${p.base01}";
            };
          }
          (rule "comment, punctuation.definition.comment" {
            foreground = p.base03;
            fontStyle = "italic";
          })
          (rule "punctuation, meta.brace, meta.preprocessor" { foreground = p.base03; })
          (rule "keyword.operator, punctuation.accessor" { foreground = p.base04; })
          (rule "keyword, storage, keyword.control.import, keyword.declaration" { foreground = p.base0E; })
          (rule "string, markup.raw" { foreground = p.base0B; })
          (rule "constant, support.constant, constant.character.escape, string.regexp" {
            foreground = p.base0A;
          })
          (rule
            "entity.name.function, support.function, variable.function, entity.name.tag, markup.underline.link"
            {
              foreground = p.base0D;
            }
          )
          (rule
            "entity.name.type, entity.name.class, entity.name.struct, entity.name.enum, entity.other.inherited-class, support.type, support.class, storage.type.primitive, storage.type.builtin"
            { foreground = p.base0C; }
          )
          (rule
            "variable, variable.parameter, variable.other, entity.name.namespace, entity.other.attribute-name, meta.property-name"
            {
              foreground = p.base05;
            }
          )
          (rule "variable.language, support.variable" {
            foreground = p.base06;
            fontStyle = "italic";
          })
          (rule "markup.heading, entity.name.section" {
            foreground = p.base06;
            fontStyle = "bold";
          })
          (rule "markup.bold" { fontStyle = "bold"; })
          (rule "markup.italic" { fontStyle = "italic"; })
          (rule "markup.quote" {
            foreground = p.base03;
            fontStyle = "italic";
          })
          (rule "markup.inserted" { foreground = p.base0B; })
          (rule "markup.changed" { foreground = p.base09; })
          (rule "markup.deleted, invalid" { foreground = p.base08; })
        ];
      }
    );

  # tuicr's own colours in the same tiers: the raised ground for the status
  # line and the cursor line, the selection laid in the selection colour,
  # pane borders like tmux's (the comment grey round the active one, the
  # faint rule round the rest), blue as the accent for where you are, orange
  # for warnings and red for errors only. Reviewed is green, and pending is
  # amber, which tuicr also blends the search highlight from -- like the
  # neovim search, the one ground laid in a hue.
  uiTheme =
    appearance: p:
    let
      c = lib.mapAttrs (_: hex: "#${hex}") p;
      addBg = "#${mix p.base00 p.base0B 0.16}";
      delBg = "#${mix p.base00 p.base08 0.12}";
    in
    {
      panel_bg = c.base00;
      bg_highlight = "#${palette.selection.${appearance}}";
      fg_primary = c.base05;
      fg_secondary = c.base04;
      fg_dim = c.base03;
      selection_marker = c.base0D;

      diff_add = c.base0B;
      diff_add_bg = addBg;
      diff_del = c.base08;
      diff_del_bg = delBg;
      diff_context = c.base05;
      diff_hunk_header = c.base0D;
      expanded_context_fg = c.base03;
      syntax_add_bg = addBg;
      syntax_del_bg = delBg;
      syntax_theme = "system-${appearance}.tmTheme";

      file_added = c.base0B;
      file_modified = c.base09;
      file_deleted = c.base08;
      file_renamed = c.base0D;

      reviewed = c.base0B;
      pending = c.base0A;

      comment_note = c.base0D;
      comment_suggestion = c.base0C;
      comment_issue = c.base08;
      comment_praise = c.base0B;

      border_focused = c.base03;
      border_unfocused = c.base02;
      status_bar_bg = c.base01;
      cursor_color = c.base0A;
      cursor_line_bg = c.base01;
      branch_name = c.base04;
      help_indicator = c.base03;

      message_info_fg = c.base00;
      message_info_bg = c.base0D;
      message_warning_fg = c.base00;
      message_warning_bg = c.base09;
      message_error_fg = c.base00;
      message_error_bg = c.base08;
      update_badge_fg = c.base00;
      update_badge_bg = c.base0A;

      mode_fg = c.base00;
      mode_bg = c.base0D;
    };

  appearances = removeAttrs palette [ "selection" ];
in
{
  options.custom.tuicr = {
    enable = lib.mkEnableOption "tuicr, a terminal ui to review diffs with vim keys";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.tuicr ];

    xdg.configFile = {
      "tuicr/config.toml".source = toml.generate "tuicr-config.toml" {
        # tuicr asks the terminal for its background, as neovim does, so
        # it switches with ghostty, see the ghostty module
        appearance = "system";
        theme_dark = "system-dark";
        theme_light = "system-light";
        # let the terminal's glass show through, as everything else does
        transparent_background = true;

        # once a file is marked reviewed it leaves the tree and the diff;
        # `:set reviewed!` brings them back
        show_reviewed = false;
        comment_vim = true;
        scroll_offset = 5;

        # updates come through nixpkgs
        no_update_check = true;
      };
    }
    // lib.concatMapAttrs (appearance: p: {
      "tuicr/themes/system-${appearance}.toml".source = toml.generate "tuicr-system-${appearance}.toml" (
        uiTheme appearance p
      );
      "tuicr/themes/system-${appearance}.tmTheme".source = syntaxTheme appearance p;
    }) appearances;

    # /tuicr: the agent opens a review pane next to itself (herdr or tmux)
    # and reads the comments left there back
    custom.claude-code.skills.tuicr = "${pkgs.tuicr.src}/skills/tuicr";
  };
}
