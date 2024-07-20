let
  digits = [
    "0"
    "1"
    "2"
    "3"
    "4"
    "5"
    "6"
    "7"
    "8"
    "9"
    "a"
    "b"
    "c"
    "d"
    "e"
    "f"
  ];
  mod = (a: b: (a - ((a / b) * b)));
  toHex = (n: (if n > 16 then toHex (n / 16) else "") + builtins.elemAt digits (mod n 16));

  toHexColor = (
    {
      r,
      g,
      b,
    }:
    "#" + toHex r + toHex g + toHex b
  );
  toRGBA255Color = (
    {
      r,
      g,
      b,
      a,
    }:
    "rgba(" + toString r + ", " + toString g + ", " + toString b + ", " + toString a + ")"
  );

  colors = {
    # polar night
    nord0 = {
      r = 46;
      g = 52;
      b = 64;
    }; # 2e3440
    nord1 = {
      r = 59;
      g = 66;
      b = 82;
    }; # 3b4252
    nord2 = {
      r = 67;
      g = 76;
      b = 94;
    }; # 434c5e
    nord3 = {
      r = 76;
      g = 86;
      b = 106;
    }; # 4c566a

    # snow storm
    nord4 = {
      r = 216;
      g = 222;
      b = 233;
    }; # d8dee9
    nord5 = {
      r = 229;
      g = 233;
      b = 240;
    }; # e5e9f0
    nord6 = {
      r = 236;
      g = 239;
      b = 244;
    }; # eceff4

    # frost
    nord7 = {
      r = 143;
      g = 188;
      b = 187;
    }; # 8fbcbb
    nord8 = {
      r = 136;
      g = 192;
      b = 208;
    }; # 88c0d0
    nord9 = {
      r = 129;
      g = 161;
      b = 193;
    }; # 81a1c1
    nord10 = {
      r = 94;
      g = 129;
      b = 172;
    }; # 5e81ac

    # aurora
    nord11 = {
      r = 191;
      g = 97;
      b = 106;
    }; # bf616a red
    nord12 = {
      r = 208;
      g = 135;
      b = 112;
    }; # d08770 orange
    nord13 = {
      r = 235;
      g = 203;
      b = 139;
    }; # ebcb8b yellow
    nord14 = {
      r = 163;
      g = 190;
      b = 140;
    }; # a3be8c green
    nord15 = {
      r = 180;
      g = 142;
      b = 173;
    }; # b48ead purple
  };
in
assert (toHexColor colors.nord0 == "#2e3440");
assert (toHexColor colors.nord1 == "#3b4252");
assert (toHexColor colors.nord2 == "#434c5e");
assert (toHexColor colors.nord3 == "#4c566a");
assert (toHexColor colors.nord4 == "#d8dee9");
assert (toHexColor colors.nord5 == "#e5e9f0");
assert (toHexColor colors.nord6 == "#eceff4");
assert (toHexColor colors.nord7 == "#8fbcbb");
assert (toHexColor colors.nord8 == "#88c0d0");
assert (toHexColor colors.nord9 == "#81a1c1");
assert (toHexColor colors.nord10 == "#5e81ac");
assert (toHexColor colors.nord11 == "#bf616a");
assert (toHexColor colors.nord12 == "#d08770");
assert (toHexColor colors.nord13 == "#ebcb8b");
assert (toHexColor colors.nord14 == "#a3be8c");
assert (toHexColor colors.nord15 == "#b48ead");
{
  inherit colors toHexColor toRGBA255Color;

  hex = builtins.mapAttrs (_: toHexColor) colors;
}
