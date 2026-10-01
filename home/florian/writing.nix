# writing setup: latex/markdown/ledger/obsidian support in neovim and a pdf viewer
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.custom.writing;
  inherit (config.sops) secrets;
in
{
  options.custom.writing.languageTool.enable = lib.mkEnableOption ''
    the LanguageTool account for ltex, decrypted from ./secrets.yaml by
    sops-nix. The machine needs the user_florian age key (see .sops.yaml) at
    ~/Library/Application Support/sops/age/keys.txt (darwin) or
    ~/.config/sops/age/keys.txt (linux); without it the sops-nix agent fails
    at every login, and on NixOS the failing user service also makes
    `nixos-rebuild switch` exit non-zero
  '';

  config = lib.mkMerge [
    {
      programs.sioyek.enable = true;

      custom.neovim.extensions = [
        {
          plugins.ledger.enable = true;

          plugins.lsp.servers.texlab.enable = true;
          plugins.vimtex = {
            enable = true;
            texlivePackage = pkgs.texliveFull;
            settings.view_method = if pkgs.stdenv.hostPlatform.isDarwin then "sioyek" else "zathura";
          };

          plugins.markdown-preview.enable = true;

          plugins.obsidian = {
            enable = true;
            settings = {
              legacy_commands = false;

              workspaces = [
                {
                  name = "singularity";
                  path = "~/vaults/singularity";
                }
              ];

              notes_subdir = "02 - Fleeting/";

              daily_notes = {
                folder = "04 - Daily/";
                date_format = "%Y-%m-%d";
              };

              templates = {
                subdir = "99 - Meta/00 - Templates/";
                date_format = "%Y-%m-%d";
                time_format = "%H:%M";
              };

              note_id_func.__raw = ''
                function(title)
                  local suffix = ""
                  if title ~= nil then
                    suffix = title:gsub(" ", "-"):gsub("[^A-Za-z0-9-]", ""):lower()
                  else
                    for _ = 1, 4 do
                      suffix = suffix .. string.char(math.random(65, 90))
                    end
                  end
                  return os.date("%Y%m%d%H%M") .. "-" .. suffix
                end
              '';
            };
          };
        }
      ];
    }

    (lib.mkIf cfg.languageTool.enable {
      # sops-nix decrypts these at login/activation using the key below (the
      # same location the sops CLI uses by default)
      sops = {
        defaultSopsFile = ./secrets.yaml;
        age.keyFile =
          if pkgs.stdenv.hostPlatform.isDarwin then
            "${config.home.homeDirectory}/Library/Application Support/sops/age/keys.txt"
          else
            "${config.xdg.configHome}/sops/age/keys.txt";

        secrets."languagetool/username" = { };
        secrets."languagetool/apiKey" = { };
      };

      custom.neovim.extensions = [
        {
          # The credentials are read when neovim starts instead of being put
          # into the store at build time. Without them (secrets not decrypted
          # yet, or the CHANGEME placeholders) the setting stays nil and ltex
          # runs without a LanguageTool account.
          lsp.servers.ltex_plus.config.settings.ltex.languageToolOrg.__raw = ''
            (function()
              local function read(path)
                local file = io.open(path, "r")
                if file == nil then
                  return nil
                end
                local value = vim.trim(file:read("*a") or "")
                file:close()
                if value == "" or value == "CHANGEME" then
                  return nil
                end
                return value
              end

              local username = read(${builtins.toJSON secrets."languagetool/username".path})
              local apiKey = read(${builtins.toJSON secrets."languagetool/apiKey".path})
              if username == nil or apiKey == nil then
                return nil
              end
              return { username = username, apiKey = apiKey }
            end)()
          '';
        }
      ];
    })
  ];
}
