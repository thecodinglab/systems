{
  infrastructure = ({ lib, ... }: {
    resource.incus_instance.poseidon = {
      name = "poseidon";
      image = "images:nixos/23.11";

      profiles = [
        "default"
        "autostart"
      ];

      config = {
        "security.privileged" = "true";
      };

      device = [
        {
          name = "share";
          type = "disk";
          properties = {
            source = "share";
            pool = "data";
            path = "/mnt/share";
          };
        }
        {
          name = "timemachine";
          type = "disk";
          properties = {
            source = "timemachine";
            pool = "data";
            path = "/mnt/timemachine";
          };
        }
        {
          name = "media-library";
          type = "disk";
          properties = {
            source = "media-library";
            pool = "data";
            path = "/mnt/media-library";
          };
        }
      ];
    };

    resource.incus_volume.share = {
      name = "share";
      pool = "data";
      type = "custom";

      config = {
        "block.filesystem" = "btrfs";
        "block.mount_options" = "noatime,discard";
        "snapshots.expiry" = "4w";
        "snapshots.schedule" = "@midnight";
      };
    };

    resource.incus_volume.timemachine = {
      name = "timemachine";
      pool = "data";
      type = "custom";

      config = {
        "block.filesystem" = "btrfs";
        "block.mount_options" = "noatime,discard";
        "snapshots.expiry" = "4w";
        "snapshots.schedule" = "@midnight";
      };
    };
  });

  system = ({ pkgs, lib, ... }:
    let
    in
    {
      networking = {
        hostName = "poseidon";
        firewall.allowedTCPPorts = [ 2049 ];
      };

      fileSystems = {
        "/export/share" = {
          device = "/mnt/share";
          options = [ "bind" ];
        };

        "/export/timemachine" = {
          device = "/mnt/timemachine";
          options = [ "bind" ];
        };

        "/export/media/library" = {
          device = "/mnt/media-library/libraries";
          options = [ "bind" ];
        };
        "/export/media/downloads" = {
          device = "/mnt/media-library/downloads/complete";
          options = [ "bind" ];
        };
      };

      users = {
        users = {
          share = {
            isSystemUser = true;
            group = "share";
          };

          timemachine = {
            isSystemUser = true;
            group = "timemachine";
          };

          media = {
            isSystemUser = true;
            group = "media";
            uid = 1000;
          };
        };

        groups = {
          share = { };
          timemachine = { };
          media = { gid = 1000; };
        };
      };

      services = {
        nfs.server = {
          enable = true;
          exports = ''
            /export                 192.168.1.0/24(ro,crossmnt,fsid=0,no_subtree_check) 
            /export/share           192.168.1.0/24(ro,nohide,insecure,no_subtree_check)
            /export/media/library   192.168.1.0/24(ro,nohide,insecure,no_subtree_check)
            /export/media/downloads 192.168.1.0/24(ro,nohide,insecure,no_subtree_check)
          '';
        };

        samba = {
          enable = true;
          securityType = "user";
          openFirewall = true;

          extraConfig = ''
            server string = poseidon
            netbios name = poseidon
            hosts allow = 192.168.1. 127.0.0.1 localhost
            hosts deny = 0.0.0.0/0

            multicast dns register = no

            guest account = nobody
          '';

          shares = {
            share = {
              path = "/mnt/share";
              browseable = "yes";
              writable = "yes";
              "valid users" = "share";
              "force user" = "share";
              "force group" = "share";
            };

            timemachine = {
              path = "/mnt/timemachine";
              browseable = "yes";
              writable = "yes";
              "valid users" = "timemachine";
              "force user" = "timemachine";
              "force group" = "timemachine";

              "fruit:aapl" = "yes";
              "fruit:time machine" = "yes";
              "vfs objects" = "catia fruit streams_xattr";
            };

            media = {
              path = "/mnt/media-library/libraries";
              browseable = "yes";
              writable = "no";
              "guest ok" = "yes";
              "force user" = "media";
              "force group" = "media";
            };
          };
        };

        avahi = {
          enable = true;
          openFirewall = true;

          publish = {
            enable = true;
            addresses = true;
          };

          extraServiceFiles = {
            smb = ''
              <?xml version="1.0" standalone='no'?><!--*-nxml-*-->
              <!DOCTYPE service-group SYSTEM "avahi-service.dtd">
              <service-group>
                <name replace-wildcards="yes">%h</name>
                <service>
                  <type>_smb._tcp</type>
                  <port>445</port>
                </service>
                 <service>
                  <type>_device-info._tcp</type>
                  <port>0</port>
                  <txt-record>model=TimeCapsule8,119</txt-record>
                </service>
                <service>
                  <type>_adisk._tcp</type>
                  <txt-record>dk0=adVN=timemachine,adVF=0x82</txt-record>
                  <txt-record>sys=waMa=0,sys=adVF=0x100</txt-record>
                </service>
              </service-group>
            '';
          };
        };
      };
    });
}
