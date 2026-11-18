{ pkgs, keys, ... }:
{
  users.users.nix = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "incus-admin"
    ];
    initialPassword = "changeme";

    shell = pkgs.zsh;

    openssh.authorizedKeys.keys = [ keys.personal ];
  };

  home-manager.users.nix = (
    { ... }:
    {
      home.stateVersion = "23.11";

      # useUserPackages would otherwise turn it on along with the system's
      # fontconfig; this user has no fonts of its own
      fonts.fontconfig.enable = false;

      custom = {
        fzf.enable = true;
        tmux.enable = true;
        zsh = {
          enable = true;
          hostname = true;
        };
      };

      # tmux.enable installs devtools (modules/home-manager/tmux.nix) and
      # this host runs no devtools server, so tmux is its default backend
      programs.devtools = {
        enable = true;
        multiplexer = "tmux";
      };

      programs.btop.enable = true;
    }
  );
}
