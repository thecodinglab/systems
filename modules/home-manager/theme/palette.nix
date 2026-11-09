# The one palette everything is drawn in, as base16, for both appearances.
#
# Quiet Colour: the grounds and four tiers of ink carry the structure --
# what you wrote in the ink, comments and punctuation in the grey -- and
# each kind of word the language supplies has a hue of its own: keywords
# purple, functions blue, types cyan, strings green, numbers and constants
# amber. The five sit at about one lightness, so none jumps out of a line,
# with enough colour to tell apart at a glance. Red is kept for errors and
# orange for warnings, and blue doubles as the accent, which says *on* or
# *here*.
#
# Every text colour clears 4.5:1 on base01, the ground of a status line and
# of the line the cursor is on, as well as on base00; the figures are on
# base00 / base01.
#
# Plain data, so the neovim package can import it too.
{
  dark = {
    base00 = "1b1c20"; # ground
    base01 = "24262b"; # status lines, the cursor line, floating windows
    base02 = "30323a"; # faint rules, inactive borders, a raised row
    base03 = "8a8d96"; # comments, punctuation, context      5.13 / 4.56
    base04 = "a6a8b0"; # muted                                7.17 / 6.38
    base05 = "c3c5cb"; # ink                                  9.87 / 8.77
    base06 = "e6e7eb"; # strong ink: titles, builtins        13.78 / 12.25
    base07 = "ffffff";
    base08 = "ef5b52"; # red, errors only                     5.10 / 4.53
    base09 = "ec8a3f"; # orange, warnings                     6.71 / 5.96
    base0A = "e6b46e"; # amber, numbers and constants         9.01 / 8.02
    base0B = "a0cc8e"; # green, strings                       9.34 / 8.31
    base0C = "7cc4cc"; # cyan, types                          8.61 / 7.66
    base0D = "84b0f0"; # blue, functions and the accent       7.66 / 6.81
    base0E = "b9a2ec"; # purple, keywords                     7.65 / 6.81
    base0F = "b09a82"; # brown                                6.32 / 5.62
  };

  light = {
    base00 = "fbfbfc";
    base01 = "f0f1f3";
    base02 = "e3e4e8";
    base03 = "686b73"; #                                      5.15 / 4.72
    base04 = "55585f"; #                                      6.89 / 6.30
    base05 = "3a3b40"; #                                     10.80 / 9.89
    base06 = "111214"; #                                     18.12 / 16.58
    base07 = "000000";
    base08 = "c4271d"; #                                      5.56 / 5.08
    base09 = "b04a00"; #                                      5.31 / 4.86
    base0A = "8a5500"; #                                      6.01 / 5.50
    base0B = "2e7536"; #                                      5.47 / 5.00
    base0C = "19707a"; #                                      5.58 / 5.10
    base0D = "2459b8"; #                                      6.35 / 5.81
    base0E = "6a45b5"; #                                      6.48 / 5.93
    base0F = "76604a"; #                                      5.73 / 5.25
  };

  # what a selection is laid in: a step off the ground toward the accent,
  # with the ink on it at 5.9:1 and 8.2:1
  selection = {
    dark = "3a4150";
    light = "d6dde9";
  };
}
