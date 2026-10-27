# macOS only parts of the user environment
{ ... }:
{
  # copy the apps from home.packages into ~/Applications/Home Manager Apps
  # instead of symlinking them, spotlight does not index symlinks into the nix
  # store; it is only the default from home.stateVersion 25.11 onwards
  targets.darwin = {
    linkApps.enable = false;
    copyApps.enable = true;
  };
}
