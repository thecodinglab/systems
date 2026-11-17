{ ... }:
{
  imports = [
    ../../home/florian
    ../../home/florian/darwin.nix
    ../../home/florian/dev.nix
    ../../home/florian/writing.nix
  ];

  # the devtools switchers on the other machines list this machine's
  # projects; "macbook" is its ssh alias
  custom.devtools.serve = {
    enable = true;
    name = "macbook";
  };

  custom.omniwm = {
    enable = true;
    displays = {
      left = {
        name = "DELL U2719D";
        displayUUID = "09060482-7767-4F77-9A5C-527FB667BEC7";
      };
      right = {
        name = "Built-in Retina Display";
        displayUUID = "37D8832A-2D66-02CA-B9F7-8F30A301B230";
      };
    };
  };
}
