{ pkgs, lib, ... }: {
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${lib.getExe pkgs.greetd.tuigreet} --time --remember --cmd Hyprland";
        user = "greeter";
      };
    };
  };

  security.pam.services.hyprlock = { };
}
