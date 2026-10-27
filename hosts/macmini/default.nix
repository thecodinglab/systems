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

  nix.linux-builder.enable = true;

  system.defaults.dock.persistent-apps = [
    "/System/Cryptexes/App/System/Applications/Safari.app"
    "/Applications/Helium.app" # managed through homebrew
    "/System/Applications/Mail.app"
    "/System/Applications/Calendar.app"

    "/Applications/Nix Apps/Ghostty.app" # managed through nix-darwin

    "/Applications/1Password.app" # managed through homebrew
    "/System/Applications/System Settings.app"
  ];

  # claude code on every host goes through this (custom.claude-code.proxy in
  # home/florian/default.nix); it listens on all interfaces for the lan,
  # clients need the key. The web panel (http://127.0.0.1:8317/management.html)
  # is only reachable from the mini itself. Setup:
  #   op item create --category password --vault Private --title CLIProxyAPI --generate-password=48,letters,digits
  #   op item create --category password --vault Private --title "CLIProxyAPI Management" --generate-password=48,letters,digits
  #   install -d -m 700 ~/.config/cliproxyapi
  #   op read "op://Private/CLIProxyAPI/password" > ~/.config/cliproxyapi/api-key
  #   op read "op://Private/CLIProxyAPI Management/password" > ~/.config/cliproxyapi/management-key
  #   cliproxyapi --claude-login && cliproxyapi --codex-login
  services.cliproxyapi = {
    enable = true;
    apiKeyFile = "/Users/florian/.config/cliproxyapi/api-key";
    managementKeyFile = "/Users/florian/.config/cliproxyapi/management-key";
    settings.server.host = "";
  };

  services.cloudflared = {
    enable = true;
    credentialsFile = "/Users/florian/.config/cloudflared/macmini.json";
    ingress = {
      "kakeibo.ch".service = "http://127.0.0.1:8080";
      "home.florian-walter.ch".service = "http://192.168.128.100:8123";
    };
  };

  services.kakeibo = {
    enable = true;
    # the "unas" remote holds the SMB password, so it is created by hand:
    #   install -d -m 700 ~/.config/kakeibo && read -rs PASS && nix run nixpkgs#rclone -- config create \
    #     unas smb host=192.168.32.185 user=florian pass="$PASS" --config ~/.config/kakeibo/rclone.conf
    backup = {
      enable = true;
      remote = "unas:Personal-Drive/Backups/kakeibo";
    };
  };

  homebrew.casks = [ "helium-browser" ];
}
