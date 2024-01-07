{ pkgs, home-manager, root, ... }: {
  users.users.nix = {
    isNormalUser = true;
    extraGroups = [ "wheel" "incus-admin" ];
    initialPassword = "changeme";

    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDC9R1U1Gk3gzGduJWdjIbnDkVHgtD5XW9FSQQAUugGof7YXntgk6BJsYYuMPqN0ot6pubEgRpYC93Ty2rYvjiIzK1CECXCgYktdkKDa/BGH420QvUPfYTN0wRb6AGjoHfzWwbObgxU/eHqRB8KcYcsr4DXzu1Sm0uZvdgxEtS9tn6vQUtO8LK5SP/FgqzE5zlhjEAouGgVQqdLql6HPR3LGZQbVsDnDrDyfiO0500ZnBOvKsqsLXo1nzxlX4DbubWd7hriuHVTaNICQhx92BbqiE2iVKBv1vCxtfgLqMekvcEkZGAxX+w641UVI2D/cyqYEqp+gIsPcUhk/fE4RGBJDihvTx1YpFdHHZi7xIhjG+CN2bzYvR9+5HM7/aahe9MsvBRph0nTvpy/F37hTFLaRDlsHrsA0E+osMvYOvPwUNWK1mgbHSmTSQT2Q5qXqUsQXvn1tEUAOIhKwWG2scHYXxi24ECUwnwRP0l4J4hH0v9Gi2i4UlsTHLdiKvb7vVh2SKEA25A4Hc1JYwAA14NGdvRGspkZJLaoxWkD3x5s1RGRiND0lOI6Z3TgllVrJCRT0PJxl+9SmFZBPpwFSFkdotyDz0xhk8q4y3Jajm+pSB5U2kefGXZEr4FDDNtOI2B0+5lXgR4xxBd6yJmS4ETo+jHuv95yoqtg7MCKRGdycw== home-server"
    ];

    shell = pkgs.zsh;
  };

  imports = [
    home-manager.nixosModules.home-manager
    {
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;

        users.nix = ({ ... }: {
          imports = [
            (root + "/modules/home-manager/tmux")
            (root + "/modules/home-manager/zsh")
          ];

          home.stateVersion = "23.11";
        });

        extraSpecialArgs = {
          inherit root;
        };
      };
    }
  ];
}
