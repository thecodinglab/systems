{ pkgs, ... }: {
  users.users.nix = {
    isNormalUser = true;
    extraGroups = [ "wheel" "incus-admin" ];
    initialPassword = "changeme";

    shell = pkgs.zsh;
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;

    users.nix = ({ ... }: {
      imports = [
        ../../../../modules/home-manager/fzf
        ../../../../modules/home-manager/tmux
        ../../../../modules/home-manager/zsh
      ];

      home.stateVersion = "23.11";
    });
  };

  imports = [
    (import ../../../../modules/common/ssh/authorized-keys.nix "nix")
  ];
}
