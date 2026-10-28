# the home dashboard, one file per view
args:
let
  # the url_path in ../../packages/dashboards.nix
  navigate = view: "/home-dashboard/${view}";

  view = file: import file (args // { inherit navigate; });
in
{
  title = "Home";
  views = map view [
    ./home.nix
    ./wake-up.nix
    ./energy.nix
    ./system.nix
    ./shutters.nix
    ./automations.nix
  ];
}
