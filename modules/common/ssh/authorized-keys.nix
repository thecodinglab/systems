user: { pkgs, lib, ... }: {
  users.users.${user}.openssh.authorizedKeys.keys =
    lib.splitString
      "\n"
      (builtins.readFile
        (builtins.fetchurl {
          name = "ssh-authorized-keys-v1";
          url = "https://github.com/thecodinglab.keys";
          sha256 = "fobgOm3SyyClt8TM74PXjyM9JjbXrXJ52na7TjJdKA0=";
        })
      );
}
