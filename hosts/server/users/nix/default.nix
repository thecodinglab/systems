{ pkgs, home-manager, ... }: {
  users.users.nix = {
    isNormalUser = true;
    extraGroups = [ "wheel" "incus-admin" ];
    initialPassword = "changeme";

    shell = pkgs.zsh;
  };

  imports = [
    (import ../../../../modules/common/ssh/authorized-keys.nix "nix")

    home-manager.nixosModules.home-manager
    {
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;

        users.nix = ({ ... }: {
          imports = [
            ../../../../modules/home-manager/tmux
            ../../../../modules/home-manager/zsh
          ];

          home.stateVersion = "23.11";
        });
      };
    }
  ];
}
