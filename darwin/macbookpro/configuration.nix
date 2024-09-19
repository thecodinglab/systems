{ outputs, pkgs, ... }:
{
  nixpkgs.overlays = [
    outputs.overlays.additions
    outputs.overlays.modifications
  ];

  custom.unfree = [
    "obsidian"
    "spotify"
  ];

  programs.gnupg.agent.enable = true;

  networking = {
    computerName = "Florian’s MacBook Pro";
    hostName = "Florians-MacBook-Pro";
    localHostName = "Florians-MacBook-Pro";
  };

  environment.systemPackages = [ pkgs.home-manager ];

  users.users.florian = {
    name = "florian";
    home = "/Users/florian/";
  };

  system.defaults.NSGlobalDomain = {
    AppleInterfaceStyleSwitchesAutomatically = true;
    NSAutomaticCapitalizationEnabled = false;
  };

  system.defaults.finder = {
    AppleShowAllExtensions = true;
    FXPreferredViewStyle = "Nlsv";
    FXDefaultSearchScope = "SCcf";
  };

  system.defaults.WindowManager = {
    # enable stage manager
    GloballyEnabled = true;
    # disable hiding of all applications when clicking on wallpaper
    EnableStandardClickToShowDesktop = false;

    AppWindowGroupingBehavior = true;
  };

  system.defaults.dock = {
    orientation = "bottom";
    show-recents = false;

    autohide = true;
    autohide-delay = 0.2;

    tilesize = 48;
    magnification = true;
    largesize = 64;

    expose-group-by-app = true;
    mru-spaces = false;

    persistent-apps = [
      "/Applications/Arc.app" # TODO: move into nix-darwin config
      "/Applications/Safari.app"
      "/System/Applications/Mail.app"
      "/Applications/Slack.app" # TODO: move into nix-darwin config
      "/System/Applications/Calendar.app"

      "${pkgs.kitty}/Applications/kitty.app"
      "${pkgs.neovide}/Applications/Neovide.app"
      "${pkgs.obsidian}/Applications/Obsidian.app"

      "${pkgs.spotify}/Applications/Spotify.app"
      "${pkgs._1password}/Applications/1Password.app"
      "/System/Applications/System Settings.app"
      "/System/Applications/iPhone Mirroring.app"
    ];

    persistent-others = [
      "/Users/florian/Documents"
      "/Users/florian/Downloads"
    ];
  };

  system.defaults.menuExtraClock = {
    ShowDate = 0;
    ShowDayOfMonth = true;
    ShowDayOfWeek = true;

    Show24Hour = true;
    ShowSeconds = true;

    IsAnalog = false;
    ShowAMPM = false;
  };

  system.stateVersion = 5;
}
