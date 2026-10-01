{ ... }:
{
  imports = [
    ../../home/florian
    ../../home/florian/darwin.nix
    ../../home/florian/dev.nix
    ../../home/florian/writing.nix
  ];

  # off by default: enable once the user_florian age key is on this machine
  # and the secret is migrated, see home/florian/writing.nix
  # custom.writing.languageTool.enable = true;

  custom.omniwm.displays = {
    left = {
      name = "DELL U2719D";
      displayUUID = "09060482-7767-4F77-9A5C-527FB667BEC7";
    };
    right = {
      name = "Built-in Retina Display";
      displayUUID = "37D8832A-2D66-02CA-B9F7-8F30A301B230";
    };
  };
}
