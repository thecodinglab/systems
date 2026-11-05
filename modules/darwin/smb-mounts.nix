# SMB shares kept mounted under /Volumes by a launchd agent that checks them
# every few minutes and mounts what is missing. Finder's login items
# only mount once at login, so a dropped connection (NAS restart, network
# hiccup, sleep) used to stay dropped until the next login.
#
# Mounting goes through NetFS (`mount volume`), like Finder: the password
# comes from the login keychain (an internet password for `server`, saved by
# ticking "Remember this password" once in Finder), and only NetFS may
# create mount points in /Volumes, which is root's.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.smb-mounts;
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;

  home = "/Users/${cfg.user}";
  logDir = "${home}/.local/state/smb-mounts";
  timeout = "${pkgs.coreutils}/bin/timeout";
in
{
  options.services.smb-mounts = {
    enable = mkEnableOption "SMB shares that are remounted when they drop";

    user = mkOption {
      type = types.str;
      default = config.system.primaryUser;
      defaultText = lib.literalExpression "config.system.primaryUser";
      description = "User the shares are mounted for, whose keychain has the password.";
    };

    server = mkOption {
      type = types.str;
      example = "UNAS-Pro._smb._tcp.local";
      description = ''
        Host of the smb:// urls, exactly as in the keychain item (its "Where"),
        otherwise the password is not found.
      '';
    };

    shares = mkOption {
      type = types.listOf types.str;
      example = [
        "Media"
        "Personal-Drive"
      ];
      description = "Shares of the server, each mounted at /Volumes/<share>.";
    };

    interval = mkOption {
      type = types.ints.positive;
      default = 120;
      description = "Seconds between two checks.";
    };
  };

  config = mkIf cfg.enable {
    system.activationScripts.postActivation.text = ''
      install -d -o ${cfg.user} -m 0700 ${lib.escapeShellArg logDir}
    '';

    launchd.user.agents.smb-mounts = {
      script = ''
        set -u
        log() { echo "$(date '+%F %T') $*"; }

        for share in ${lib.escapeShellArgs cfg.shares}; do
          mountpoint="/Volumes/$share"
          url="smb://${cfg.user}@${cfg.server}/$share"

          # only the mount table, never the files: looking into the volume needs
          # the "network volumes" permission, which macOS asks for again with
          # every new store path of the agent. A mount that is still listed
          # either works or is reconnected by smbfs once the server is back.
          if mount -t smbfs | grep -qF " on $mountpoint (smbfs"; then
            continue
          fi

          log "mounting $url"
          if ! ${timeout} -k 5 60 osascript -e "mount volume \"$url\"" > /dev/null; then
            log "mounting $url failed, next try in ${toString cfg.interval}s"
          elif ! mount -t smbfs | grep -qF " on $mountpoint (smbfs"; then
            # NetFS picks <share>-1 if a stale directory blocks /Volumes/<share>
            log "$url is not mounted at $mountpoint, see: mount -t smbfs"
          fi
        done
      '';
      serviceConfig = {
        RunAtLoad = true;
        StartInterval = cfg.interval;
        # only in the gui session, which has the keychain and NetFS
        LimitLoadToSessionType = "Aqua";
        StandardOutPath = "${logDir}/smb-mounts.log";
        StandardErrorPath = "${logDir}/smb-mounts.log";
      };
    };
  };
}
