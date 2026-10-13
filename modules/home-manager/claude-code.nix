# claude code with declarative settings, optionally talking to a CLIProxyAPI
# instance (see modules/darwin/cliproxyapi.nix) instead of using its own login.
# ~/.claude/settings.json is written by claude itself, so the settings are
# passed with --settings instead: they take precedence over the ones in that
# file, which is left for whatever is changed interactively (theme, model, ...)
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.custom.claude-code;
  inherit (lib) mkOption types;

  format = pkgs.formats.json { };
  settingsFile = format.generate "claude-code-settings.json" cfg.settings;

  package =
    if cfg.settings != { } then
      pkgs.symlinkJoin {
        # same name as the package, which is on the unfree allowlist
        inherit (cfg.package) pname version meta;
        paths = [ cfg.package ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/claude --add-flags "--settings ${settingsFile}"
        '';
      }
    else
      cfg.package;
in
{
  options.custom.claude-code = {
    enable = lib.mkEnableOption "claude code";

    package = lib.mkPackageOption pkgs "claude-code" { };

    settings = mkOption {
      type = format.type;
      default = { };
      example = {
        editorMode = "vim";
        permissions.defaultMode = "bypassPermissions";
      };
      description = ''
        Settings, see <https://code.claude.com/docs/en/settings>. They override
        ~/.claude/settings.json, so changing them interactively has no effect.
      '';
    };

    proxy = {
      enable = lib.mkEnableOption "sending the requests of claude code through CLIProxyAPI";

      url = mkOption {
        type = types.str;
        example = "http://192.168.48.124:8317";
        description = "Base url of the CLIProxyAPI server (ANTHROPIC_BASE_URL).";
      };

      apiKeyCommand = mkOption {
        type = types.str;
        example = ''op read "op://Private/CLIProxyAPI/password"'';
        description = "Shell command printing the key of the server (apiKeyHelper).";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ package ];

    # https://help.router-for.me/agent-client/claude-code.html
    custom.claude-code.settings = lib.mkIf cfg.proxy.enable {
      apiKeyHelper = cfg.proxy.apiKeyCommand;
      env = {
        ANTHROPIC_BASE_URL = cfg.proxy.url;
        # the key never changes, so only ask for it again after a 401 (or a day)
        CLAUDE_CODE_API_KEY_HELPER_TTL_MS = toString (24 * 60 * 60 * 1000);
        # lists the models of the proxy in /model, including the ones of other
        # subscriptions (codex), which the proxy maps to claude-fable-5-dd-<id>
        CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY = "1";
        # translated requests to other providers can take a while
        API_TIMEOUT_MS = toString (10 * 60 * 1000);
      };
    };
  };
}
