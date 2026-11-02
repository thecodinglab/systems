# The one palette everything is drawn in, as base16, for both appearances.
#
# Quiet: almost monochrome. The grounds and four tiers of ink carry nearly
# all of it -- what you wrote in the ink, what the language says in a
# brighter, bolder one, comments and punctuation in the grey -- and the few
# hues are pulled most of the way to grey, so a colour on screen is either
# a literal (strings green, numbers amber) or a signal: red for an error,
# orange for a warning, blue for the accent, which only ever says *on* or
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
    base06 = "e6e7eb"; # strong ink: keywords, definitions   13.78 / 12.25
    base07 = "ffffff";
    base08 = "ef5b52"; # red, errors only                     5.10 / 4.53
    base09 = "ec8a3f"; # orange, warnings                     6.71 / 5.96
    base0A = "d6b98a"; # amber, numbers and constants         9.05 / 8.05
    base0B = "9cc4a4"; # green, strings                       8.79 / 7.82
    base0C = "8fc0c9"; # cyan                                 8.55 / 7.61
    base0D = "8fb0e8"; # blue, the accent                     7.74 / 6.88
    base0E = "b8a6dc"; # purple                               7.72 / 6.87
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
    base0A = "7f5a12"; #                                      6.02 / 5.51
    base0B = "2f7543"; #                                      5.42 / 4.96
    base0C = "25707f"; #                                      5.48 / 5.02
    base0D = "2f5fb3"; #                                      5.96 / 5.45
    base0E = "6d4fa3"; #                                      6.16 / 5.63
    base0F = "76604a"; #                                      5.73 / 5.25
  };

  # what a selection is laid in: a step off the ground toward the accent,
  # with the ink on it at 5.9:1 and 8.2:1
  selection = {
    dark = "3a4150";
    light = "d6dde9";
  };
}
