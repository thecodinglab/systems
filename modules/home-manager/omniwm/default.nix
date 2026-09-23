{
  config,
  lib,
  ...
}:
{
  options.custom.omniwm = {
    enable = lib.mkEnableOption "enable omniwm";
  };

  config = lib.mkIf config.custom.omniwm.enable {
    programs.omniwm = {
      enable = true;

      # OmniWM validates settings.toml as a whole: every table and every
      # hotkey id has to be present, so this spells out the complete file.
      # See https://omniwm.app/config/settings-reference/
      settings =
        let
          # display identities as reported by CoreGraphics; a workspace can
          # only be pinned to a specific display through its uuid.
          displays = {
            left = {
              name = "DELL U2719D";
              displayUUID = "09060482-7767-4F77-9A5C-527FB667BEC7";
            };
            right = {
              name = "Built-in Retina Display";
              displayUUID = "37D8832A-2D66-02CA-B9F7-8F30A301B230";
            };
          };

          onMain = {
            type = "main";
          };
          onDisplay = output: {
            type = "specificDisplay";
            inherit output;
          };

          workspace = id: name: monitorAssignment: {
            inherit id name monitorAssignment;
            layoutType = "default";
          };

          color = red: green: blue: alpha: {
            inherit
              red
              green
              blue
              alpha
              ;
          };

          floating = [
            "com.apple.finder"
            "com.apple.iCal"
            "com.apple.calculator"
            "com.apple.systempreferences"
            "com.apple.ScreenSharing"
            "com.apple.reminders"

            "com.spotify.client"
            "com.1password.1password"
            "net.whatsapp.WhatsApp"
            "com.tinyspeck.slackmacgap"

            "com.openai.chat"
            "com.openai.codex"
            "com.anthropic.claudefordesktop"
          ];

          # upstream default rules: minimum sizes for apps with known resize floors
          minSize = minWidth: minHeight: { inherit minWidth minHeight; };
          minimumSizes = {
            "com.openai.codex" = minSize 800.0 600.0;
            "com.eltima.cmd1.pro.mas" = minSize 950.0 550.0;
            "com.google.Chrome" = minSize 500.0 375.0;
            "dev.zed.Zed" = minSize 360.0 240.0;
            "com.apple.Safari" = minSize 574.0 220.0;
            "app.zen-browser.zen" = minSize 500.0 495.0;
            "org.mozilla.firefox" = minSize 500.0 120.0;
            "company.thebrowser.dia" = minSize 500.0 420.0;
            "com.spotify.client" = minSize 800.0 600.0;
            "com.hnc.Discord" = minSize 800.0 500.0;
            "com.mitchellh.ghostty" = minSize 90.0 48.0;
            "com.microsoft.Outlook" = minSize 930.0 650.0;
            "com.apple.MobileSMS" = minSize 660.0 320.0;
          };

          hotkeys = import ./hotkeys.nix // {
            "focus.left" = "Option+H";
            "focus.down" = "Option+J";
            "focus.up" = "Option+K";
            "focus.right" = "Option+L";

            "move.left" = "Option+Shift+H";
            "move.down" = "Option+Shift+J";
            "move.up" = "Option+Shift+K";
            "move.right" = "Option+Shift+L";

            "setContainerPrimarySpan.decrease10Percent" = "Option+Minus";
            "setContainerPrimarySpan.increase10Percent" = "Option+Equal";

            "workspaceBackAndForth" = "Option+Tab";
            "focusPrevious" = "Unassigned"; # frees Option+Tab

            "moveWorkspaceToMonitor.left" = "Control+Option+Shift+Tab";
            "moveWorkspaceToMonitor.right" = "Option+Shift+Tab";

            "toggleFullscreen" = "Option+M";
            "toggleQuakeTerminal" = "Option+Return";
            "toggleWorkspaceLayout" = "Option+Shift+T"; # default Option+Shift+L now moves right
          };
        in
        {
          schemaVersion = 3;

          general = {
            hotkeysEnabled = true;
            systemHyperTrigger = "None";
            hyperKeyModifiers = "Control+Option+Shift+Command";
            defaultLayoutType = "niri";
            preventSleepEnabled = false;
            updateChecksEnabled = false; # managed through nix
            ipcEnabled = true; # required for omniwmctl
            animationsEnabled = true;
          };

          focus = {
            followsMouse = false;
            raiseOnMouseFocus = false;
            lockModifier = "off";
            moveMouseToFocusedWindow = true;
            followsWindowToMonitor = false;
            crossesMonitorAtEdge = false;
            moveCrossesMonitorAtEdge = false;
          };

          mouseWarp = {
            margin = 1;
            enabled = true;
            constrainToArrangement = false;
          };

          routing = {
            mode = "macOS";
            arrangements = [ ];
          };

          gaps = {
            size = 8.0;
            fullscreenUsesOuterGaps = false;
            outer = {
              left = 8.0;
              right = 8.0;
              top = 8.0;
              bottom = 8.0;
            };
          };

          niri = {
            visibleContainerCount = 2;
            infiniteLoop = false;
            centerFocusedColumn = "never";
            alwaysCenterSingleColumn = false;
            singleWindowFit = "fill";
          };

          dwindle = {
            smartSplit = false;
            defaultSplitRatio = 1.0;
            splitWidthMultiplier = 1.0;
            singleWindowFit = "fill";
            useGlobalGaps = true;
            moveToRootStable = true;
          };

          borders = {
            enabled = false;
            width = 5.0;
            color = color 0.08 1.0 0.98 1.0;
          };

          overview = {
            zoom = 1.0;
            backdrop = color 0.05 0.05 0.08 1.0;
            windowBorders = {
              normal = color 0.3 0.3 0.35 0.5;
              hovered = color 0.4 0.6 1.0 1.0;
              selected = color 0.3 0.8 0.4 1.0;
            };
          };

          workspaceBar = {
            enabled = true;
            showLabels = true;
            showFloatingWindows = false;
            windowLevel = "popup";
            position = "overlappingMenuBar";
            notchMode = "moveBelowMenuBar";
            notchActiveZoneWidth = 180.0;
            systemStatsButton = false;
            deduplicateAppIcons = false;
            hideEmptyWorkspaces = false;
            excludedBundleIDs = [ ];
            iconOverrides = { };
            reserveLayoutSpace = false;
            revealModifier = "off";
            revealHoldMilliseconds = 200.0;
            hideInNativeFullscreen = false;
            height = 24.0;
            backgroundOpacity = 0.1;
            xOffset = 0.0;
            yOffset = 0.0;
          };

          gestures = {
            scrollEnabled = true;
            scrollSensitivity = 5.0;
            scrollModifierKey = "optionShift";
            mouseMoveModifierKey = "option";
            mouseResizeModifierKey = "option";
            fingerCount = 3;
            invertDirection = true;
            trackpadScrollStyle = "snap";
            workspaceSwipeEnabled = false;
            workspaceSwipeFingerCount = 3;
            workspaceSwipeAxis = "vertical";
          };

          statusBar = {
            showWorkspaceName = false;
            showAppNames = false;
            useWorkspaceId = false;
          };

          hiddenBar = {
            enabled = true;
            hiddenBundleIDs = [ ];
            rehideIntervalSeconds = 5.0;
          };

          clipboard = {
            historyEnabled = false;
            maxItems = 200;
            maxItemBytes = 8388608;
            maxTotalBytes = 67108864;
          };

          quakeTerminal = {
            enabled = true;
            position = "center";
            widthPercent = 50.0;
            heightPercent = 50.0;
            animationDuration = 0.2;
            autoHide = false;
            backgroundEffect = "standardBlur";
          };

          scratchpads.labels = { };

          appearance.mode = "automatic";

          hotkeys = lib.mapAttrsToList (id: binding: { inherit id binding; }) hotkeys;

          workspaces = [
            # left
            (workspace "AD36F001-C57E-41A5-AC1D-DF5249D007F0" "1" (onDisplay displays.left))
            (workspace "454CECD4-5E9D-4ED1-95D7-979D48817F5F" "2" (onDisplay displays.left))

            # center
            (workspace "BEB842B5-E894-4791-9FD1-397C3CDD3538" "3" onMain)
            (workspace "5953F2BF-A378-4266-91B2-287174C4FA4D" "6" onMain)
            (workspace "A7D5E104-6985-4516-8ED5-07F144F2A33D" "7" onMain)
            (workspace "0E18F6B0-345A-4078-8B21-33641F07A861" "8" onMain)
            (workspace "8D4D711C-2B2F-4FEC-86BF-FA952037738A" "9" onMain)

            # right
            (workspace "248AA883-2261-4D45-943C-79C0E46A232B" "4" (onDisplay displays.right))
            (workspace "8B8C45D6-CE9E-41D9-BD50-BE4989D5E3DE" "5" (onDisplay displays.right))
          ];

          appRules =
            map (bundleId: {
              inherit bundleId;
              layout = "float";
            }) floating
            ++ lib.mapAttrsToList (bundleId: size: { inherit bundleId; } // size) minimumSizes;

          monitorBarOverrides = [ ];
          monitorOrientationOverrides = [ ];
          monitorNiriOverrides = [ ];
          monitorDwindleOverrides = [ ];
          monitorGapOverrides = [ ];
        };
    };
  };
}
