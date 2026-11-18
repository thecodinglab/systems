{ config, ... }:
{
  imports = [
    ../../home/florian
    ../../home/florian/darwin.nix
  ];

  # the other machines, by ssh alias, dialled on demand (F12); nothing is
  # held open while nobody sits here
  programs.devtools.machines = {
    desktop = { };
    macbook = { };
  };

  # ssh keys come from the machine you log in from, see the ssh module
  custom.ssh.forwardedAgents.enable = true;
  # and so do the keys of the devtools panes, which the server starts
  programs.devtools.server.environment.SSH_AUTH_SOCK = config.custom.ssh.forwardedAgents.socket;

  # the proxy runs right here (./default.nix), no need to ask 1password
  custom.claude-code.proxy = {
    url = "http://127.0.0.1:8317";
    apiKeyCommand = "cat ~/.config/cliproxyapi/api-key";
    apiKeyCacheFile = null;
    # the proxy is on this machine, if it is down so is the fallback's reason
    # to exist; claude-direct still skips it
    fallback = false;
  };
}
