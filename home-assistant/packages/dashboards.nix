# the yaml mode dashboards from ../dashboards and the module that loads their
# cards. Home assistant only reads both when it starts, deploy.nix says when
# that is needed
{
  dashboardFile,
  wwwUrl,
  ...
}:
{
  lovelace.dashboards = {
    # the url is also in ../dashboards/home/default.nix
    home-dashboard = {
      mode = "yaml";
      filename = dashboardFile "home";
      title = "Home";
      icon = "mdi:home-lightbulb-outline";
      show_in_sidebar = true;
      require_admin = false;
    };
  };

  # see ../www/loader.js
  frontend.extra_module_url = [ "${wwwUrl}/loader.js" ];
}
