{ config, lib, ... }:
# System tuning adapted from omarchy (https://github.com/basecamp/omarchy). See
# its etc/ and default/systemd directories for the original rationale.
{
  config = lib.mkIf config.custom.desktop.enable {
    #######################
    # Memory              #
    #######################

    # Compressed swap in RAM. zstd averages around 3:1, so even a full device
    # occupies roughly a third of RAM. A smaller cap spills reclaim to disk.
    zramSwap = {
      enable = true;
      algorithm = "zstd";
      memoryPercent = 100;
    };

    boot.kernel.sysctl = {
      # Solve common flakiness with SSH (MTU discovery on flaky links).
      "net.ipv4.tcp_mtu_probing" = 1;

      # Tune reclaim for swap on zram, which is orders of magnitude faster than
      # the disk swap these defaults assume.

      # Above 100 tells the kernel that evicting an anonymous page is cheaper
      # than dropping a page-cache page it would have to re-read from disk.
      # With a compressed RAM device that is true, so the disk-era default of
      # 60 leaves the page cache starved. Stop at 150: every page swapped still
      # costs a compression now and a decompression on fault-back.
      "vm.swappiness" = 150;

      # Halve the eagerness to drop dentry/inode cache, which is costly to
      # rebuild and can't spill to zram. Not lower: 0 can OOM.
      "vm.vfs_cache_pressure" = 50;

      # Read one page per swap-in fault. The default of 8 pays for a seek that
      # zram doesn't have, and every extra page costs a separate decompression.
      "vm.page-cluster" = 0;

      # Don't let external fragmentation raise the watermarks, which produces
      # reclaim bursts while memory is still free.
      "vm.watermark_boost_factor" = 0;

      # Keep ~1.25% of memory free instead of 0.1%, so kswapd reclaims in the
      # background rather than letting allocations stall in direct reclaim.
      "vm.watermark_scale_factor" = 125;

      # Cap dirty pages at 64M/256M instead of the default 10%/20% of RAM,
      # which lets gigabytes of writeback pile up and flush in stalling bursts.
      "vm.dirty_background_bytes" = 67108864;
      "vm.dirty_bytes" = 268435456;

      # With bursts bounded above, the flusher can wake every 15s instead of 5s.
      "vm.dirty_writeback_centisecs" = 1500;
    };

    #######################
    # Boot & Shutdown     #
    #######################

    # Never autosuspend USB devices; it makes keyboards, mice and audio
    # interfaces drop out or lag on wake. usbcore is built in, so this has to
    # go on the kernel command line rather than into modprobe.d.
    boot.kernelParams = [ "usbcore.autosuspend=-1" ];

    # Don't let network-online.target hold up the graphical session waiting
    # for DHCP. Nothing in the session needs to block on the network.
    systemd.network.wait-online.enable = false;

    # Don't wait 90s for a hung service on shutdown.
    systemd.settings.Manager = {
      DefaultTimeoutStopSec = "5s";
      DefaultLimitNOFILE = "65536:524288";
    };
    systemd.services."user@" = {
      overrideStrategy = "asDropin";
      serviceConfig.TimeoutStopSec = "5s";
    };
    systemd.user.settings.Manager.DefaultLimitNOFILE = "65536:524288";

    # hypridle locks the session before suspend through a delay inhibitor,
    # which is a timer, not a promise: logind suspends anyway once the window
    # expires. Five seconds is not always enough for the lock to come up.
    services.logind.settings.Login.InhibitDelayMaxSec = 15;

    #######################
    # Network             #
    #######################

    # avahi already answers mDNS; resolved competing on the same port only adds
    # noise, and LLMNR is a Windows-era fallback nothing here needs.
    services.resolved.settings.Resolve = {
      LLMNR = "no";
      MulticastDNS = "no";
    };

    # Notice dropped SSH connections within a minute instead of hanging until
    # TCP gives up. ~/.ssh/config is read first and wins, so hosts can still
    # override these.
    programs.ssh.extraConfig = ''
      Host *
        ServerAliveInterval 15
        ServerAliveCountMax 3
        ConnectTimeout 10
    '';

    #######################
    # Applications        #
    #######################

    # Keep container logs bounded instead of growing until the disk is full.
    virtualisation.docker.daemon.settings = lib.mkIf config.virtualisation.docker.enable {
      log-driver = "json-file";
      log-opts = {
        max-size = "10m";
        max-file = "5";
      };
    };

    # Map the web/Electron platform font families onto the generic families
    # so pages asking for the macOS system font render with the configured
    # sans-serif instead of whatever fontconfig scans up first.
    fonts.fontconfig.localConf = ''
      <?xml version="1.0"?>
      <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
      <fontconfig>
        <alias>
          <family>system-ui</family>
          <prefer><family>sans-serif</family></prefer>
        </alias>
        <alias>
          <family>-apple-system</family>
          <prefer><family>sans-serif</family></prefer>
        </alias>
        <alias>
          <family>BlinkMacSystemFont</family>
          <prefer><family>sans-serif</family></prefer>
        </alias>
        <alias>
          <family>ui-monospace</family>
          <default><family>monospace</family></default>
        </alias>
      </fontconfig>
    '';
  };
}
