{ ... }:
{
  imports = [
    ../../home/florian
    ../../home/florian/darwin.nix
  ];

  # the proxy runs right here (./default.nix), no need to ask 1password
  custom.claude-code.proxy = {
    url = "http://127.0.0.1:8317";
    apiKeyCommand = "cat ~/.config/cliproxyapi/api-key";
  };
}
