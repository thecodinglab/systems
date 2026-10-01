{ inputs, ... }:
{
  imports = [
    ../../profiles/darwin/workstation.nix
    inputs.kakeibo.darwinModules.default
  ];

  networking = {
    computerName = "Florian’s Mac mini";
    hostName = "Florians-Mac-Mini";
    localHostName = "Florians-Mac-Mini";
  };

  home-manager.users.florian = ./home.nix;

  system.defaults.dock.persistent-apps = [
    "/System/Cryptexes/App/System/Applications/Safari.app"
    "/System/Applications/Mail.app"
    "/System/Applications/Calendar.app"

    "/Applications/Nix Apps/Ghostty.app" # managed through nix-darwin

    "/Applications/1Password.app" # managed through homebrew
    "/System/Applications/System Settings.app"
  ];

  services.ollama = {
    enable = true;
    models = [ "qwen2.5:14b" ];
    environment.OLLAMA_KEEP_ALIVE = "30m";
  };

  services.kakeibo = {
    enable = true;
    listen = "0.0.0.0:8080"; # reachable from the local network; kakeibo has no authentication
    environment = {
      KAKEIBO_LLM_BASE_URL = "http://127.0.0.1:11434/v1";
      KAKEIBO_LLM_MODEL = "qwen2.5:14b";
    };
    # the "unas" remote holds the SMB password, so it is created by hand:
    #   install -d -m 700 ~/.config/kakeibo && read -rs PASS && nix run nixpkgs#rclone -- config create \
    #     unas smb host=192.168.32.185 user=florian pass="$PASS" --config ~/.config/kakeibo/rclone.conf
    backup = {
      enable = true;
      remote = "unas:Personal-Drive/Backups/kakeibo";
    };
  };
}
