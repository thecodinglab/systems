{ pkgs, lib, ... }: {
  programs.hyprland = {
    enable = true;
    xwayland.enable = false;
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
}
