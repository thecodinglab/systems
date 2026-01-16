{ pkgs, lib, ... }:
{
  imports = [ ./minimal.nix ];

  extraPlugins = [
    pkgs.vimPlugins.vim-prettier
    pkgs.vimPlugins.vim-vsnip
  ];

  files = {
    "ftplugin/proto.lua" = {
      opts.commentstring = "// %s";
    };
  };

  keymaps = [
    # toggle diagnostics
    {
      key = "<leader>d";
      mode = [ "n" ];
      action = lib.nixvim.mkRaw ''
        function ()
          vim.diagnostic.enable(not vim.diagnostic.is_enabled())
        end
      '';
    }

    # lsp
    {
      key = "gd";
      mode = [ "n" ];
      action = "<cmd>FzfLua lsp_definitions<cr>";
    }
    {
      key = "grr";
      mode = [ "n" ];
      action = "<cmd>FzfLua lsp_references<cr>";
    }
    {
      key = "gra";
      mode = [ "n" ];
      action = "<cmd>FzfLua lsp_code_actions<cr>";
    }
  ];

  autoCmd = [
    # disable syntax highlight on large files
    # inspired by https://github.com/LunarVim/bigfile.nvim/blob/33eb067e3d7029ac77e081cfe7c45361887a311a/lua/bigfile/features.lua
    {
      event = [ "BufReadPre" ];
      callback = lib.nixvim.mkRaw ''
        function (args)
          local max_filesize = 100 * 1024 -- 100 KB
          local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(args.buf))
          if ok and stats and stats.size > max_filesize then
            vim.opt_local.swapfile = false
            vim.opt_local.foldmethod = "manual"

            vim.api.nvim_buf_set_var(args.buf, "bigfile_disable_treesitter", 1)
          end
        end
      '';
    }

    {
      event = "LspAttach";
      callback = lib.nixvim.mkRaw ''
        function (args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)

          if client.server_capabilities.documentFormattingProvider and client.name ~= "tsserver" and client.name ~= "ts_ls" then
            vim.api.nvim_create_autocmd({ "BufWritePre" }, {
              buffer = args.buf,
              group = vim.api.nvim_create_augroup("lsp_autoformat", { clear = false }),
              callback = function()
                vim.lsp.buf.format({ 
                  bufnr = args.buf,
                  async = false,
                  timeout_ms = 150,
                })
              end,
            })
          end

          if client.name == "gopls" then
            vim.api.nvim_create_autocmd({ "BufWritePre" }, {
              buffer = args.buf,
              group = vim.api.nvim_create_augroup("lsp_go_organize_imports", { clear = false }),
              callback = function()
                local params = vim.lsp.util.make_formatting_params()
                params.context = {
                  only = { "source.organizeImports" }
                }

                local result = vim.lsp.buf_request_sync(0, "textDocument/codeAction", params, timeout)
                for _, res in pairs(result or {}) do
                  for _, r in pairs(res.result or {}) do
                    if r.edit then
                      vim.lsp.util.apply_workspace_edit(r.edit, "utf-8")
                    else
                      vim.lsp.buf.execute_command(r.command)
                    end
                  end
                end
              end,
            })
          end

          if client.server_capabilities.documentHighlightProvider then
            vim.api.nvim_create_autocmd({ "CursorHold" }, {
              buffer = args.buf,
              group = vim.api.nvim_create_augroup("lsp_document_highlight_hold", { clear = false }),
              callback = function()
                vim.lsp.buf.document_highlight()
              end,
            })

            vim.api.nvim_create_autocmd({ "CursorMoved" }, {
              buffer = args.buf,
              group = vim.api.nvim_create_augroup("lsp_document_highlight_moved", { clear = false }),
              callback = function()
                vim.lsp.buf.clear_references()
              end,
            })
          end
        end
      '';
    }
    {
      event = "LspDetach";
      callback = lib.nixvim.mkRaw ''
        function (args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)

          if client.server_capabilities.documentFormattingProvider then
            vim.api.nvim_clear_autocmds({ 
              buffer = args.buf,
              group = vim.api.nvim_create_augroup("lsp_autoformat", { clear = false }),
            })
          end

          if client.name == "gopls" then
            vim.api.nvim_clear_autocmds({ 
              buffer = args.buf,
              group = vim.api.nvim_create_augroup("lsp_go_organize_imports", { clear = false }),
            })
          end

          if client.server_capabilities.documentHighlightProvider then
            vim.lsp.buf.clear_references()

            vim.api.nvim_clear_autocmds({ 
              buffer = args.buf,
              group = vim.api.nvim_create_augroup("lsp_document_highlight_hold", { clear = false }),
            })
            vim.api.nvim_clear_autocmds({ 
              buffer = args.buf,
              group = vim.api.nvim_create_augroup("lsp_document_highlight_moved", { clear = false }),
            })
          end
        end
      '';
    }
  ];

  extraConfigLua = ''
    -- Custom LSP {{{
    do
      local curl = require("plenary.curl")

      vim.lsp.commands["_ltex.addToDictionary"] = function (command, context)
        local args = command.arguments[1]
        local client = vim.lsp.get_client_by_id(context.client_id)

        local settings = client.settings and client.settings.ltex
        local endpoint = settings and settings.languageToolHttpServerUri
        local username = settings and settings.languageToolOrg and settings.languageToolOrg.username
        local apiKey = settings and settings.languageToolOrg and settings.languageToolOrg.apiKey

        if not (endpoint and username and apiKey) then
          return
        end

        for lang, words in pairs(args.words) do
          for _, word in pairs(words) do
            curl.post(endpoint .. "v2/words/add", {
              body = {
                word = word,
                username = username,
                apiKey = apiKey,
              },
            })
          end
        end

        client.request("workspace/executeCommand", { command = "_ltex.checkDocument", arguments = { { uri = args.uri } } })
      end

      vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(
        vim.lsp.handlers.hover,
        { max_width = 80 }
      )

      vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(
        vim.lsp.handlers.signature_help,
        { max_width = 80 }
      )
    end
    -- }}}
  '';

  plugins = {
    treesitter = {
      enable = true;
      folding.enable = true;

      grammarPackages = pkgs.vimPlugins.nvim-treesitter.passthru.allGrammars;

      settings =
        builtins.mapAttrs
          (
            name: value:
            value
            // {
              disable = lib.nixvim.mkRaw ''
                function(lang, buf)
                  local success, detected = pcall(vim.api.nvim_buf_get_var, buf, "bigfile_disable_treesitter")
                  return success and detected
                end
              '';
            }
          )
          {
            highlight.enable = true;
            incremental_selection.enable = true;
            indent.enable = true;
          };
    };

    treesitter-context = {
      enable = true;
      settings.enable = false;
    };

    lsp = {
      enable = true;
      inlayHints = true;

      keymaps.lspBuf = {
        "grf" = "format";
      };

      servers = {
        ltex = {
          enable = true;
          settings = {
            additionalRules = {
              motherTongue = "de-CH";
              enablePickyRules = true;
            };

            languageToolHttpServerUri = "https://api.languagetoolplus.com/";
            languageToolOrg = (import ./secrets.nix).languageTool;
          };
        };

        nixd = {
          enable = true;
          settings.formatting.command = [ (lib.getExe pkgs.nixfmt) ];
        };

        gopls = {
          enable = true;
          settings.gopls.gofumpt = true;
          extraOptions.on_new_config = lib.nixvim.mkRaw ''
            function(new_config, new_root_dir)
              if vim.uv.fs_stat(new_root_dir .. "/go.mod") then
                local res = vim.system({ "go", "list", "-m" }, {
                  cwd = new_root_dir,
                  text = true
                }):wait()

                if res.code == 0 then
                  new_config.settings.gopls["local"] = vim.trim(res.stdout)
                end
              end
            end
          '';
        };

        ts_ls.enable = true;
        biome.enable = true;
        tailwindcss = {
          enable = true;
          settings.tailwindCSS.experimental.classRegex = [
            [
              "cva\\(([^)]*)\\)"
              "[\"'`]([^\"'`]*).*?[\"'`]"
            ]
            [
              "cn\\(([^)]*)\\)"
              "(?:'|\"|`)([^']*)(?:'|\"|`)"
            ]
          ];
        };

        clangd = {
          enable = true;
          # everything except `proto`
          filetypes = [
            "c"
            "cpp"
            "objc"
            "objcpp"
            "cuda"
          ];
        };

        rust_analyzer = {
          enable = true;
          installCargo = false;
          installRustc = false;
        };
      };
    };

    gitsigns.enable = true;
    neogit.enable = true;

    trouble.enable = true;
    fidget.enable = true;

    blink-cmp = {
      enable = true;
      settings = {
        appearance.nerd_font_variant = "normal";

        completion = {
          keyword.range = "full";

          accept = {
            auto_brackets = {
              enabled = true;
              semantic_token_resolution = {
                enabled = false;
              };
            };
          };

          documentation.auto_show = true;
        };

        signature.enabled = true;

        sources = { };

        keymap = {
          preset = "none";

          "<C-e>" = [ "hide" ];
          "<C-y>" = [ "select_and_accept" ];

          "<C-p>" = [
            "select_prev"
            "fallback_to_mappings"
          ];
          "<C-n>" = [
            "show"
            "select_next"
            "fallback_to_mappings"
          ];

          "<C-b>" = [
            "scroll_documentation_up"
            "fallback"
          ];
          "<C-f>" = [
            "scroll_documentation_down"
            "fallback"
          ];

          "<Tab>" = [
            "snippet_forward"
            "fallback"
          ];
          "<S-Tab>" = [
            "snippet_backward"
            "fallback"
          ];

          "<C-k>" = [
            "show_signature"
            "hide_signature"
            "fallback"
          ];
        };
      };
    };

    colorizer = {
      enable = true;
      settings = {
        user_default_options = {
          names = false;
          hsl_fn = true;

          tailwind = "lsp";
        };
      };
    };
  };
}
