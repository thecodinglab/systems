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

      programs.btop.enable = true;
    }
  );
}
