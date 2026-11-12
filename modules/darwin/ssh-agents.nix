# /etc/ssh/sshrc for the home-manager users with custom.ssh.forwardedAgents
# (modules/home-manager/ssh.nix): sshd runs it with /bin/sh in every login's
# environment, sftp/scp included, as long as the user has no ~/.ssh/rc
{ config, lib, ... }:
let
  users = lib.filter (user: user.custom.ssh.forwardedAgents.enable or false) (
    lib.attrValues config.home-manager.users
  );
in
{
  config = lib.mkIf (users != [ ]) {
    environment.etc."ssh/sshrc".text = ''
      case $HOME in
      ${
        lib.concatMapStrings (user: ''
          ${lib.escapeShellArg user.home.homeDirectory}) ${user.custom.ssh.forwardedAgents.registerScript} ;;
        '') users
      }esac

      # with an sshrc, sshd leaves the X11 cookie to it, see sshd(8)
      if [ -n "''${DISPLAY-}" ] && command -v xauth >/dev/null 2>&1 && read proto cookie; then
        if [ "$(echo "$DISPLAY" | cut -c1-10)" = 'localhost:' ]; then
          echo add "unix:$(echo "$DISPLAY" | cut -c11-)" "$proto" "$cookie"
        else
          echo add "$DISPLAY" "$proto" "$cookie"
        fi | xauth -q -
      fi
    '';
  };
}
