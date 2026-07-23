{ pkgs, lib, ... }:
{
  imports = [ ./minimal.nix ];

  # used by the custom ltex command handler (plenary.curl)
  extraPlugins = [
    pkgs.vimPlugins.plenary-nvim
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
          local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(args.buf))
          if ok and stats and stats.size > max_filesize then
            vim.opt_local.swapfile = false
            vim.opt_local.foldmethod = "manual"
            pcall(vim.treesitter.stop, args.buf)
          end
        end
      '';
    }

    {
      event = "LspAttach";
      callback = lib.nixvim.mkRaw ''
        function (args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)

          if client:supports_method("textDocument/formatting") and client.name ~= "tsserver" and client.name ~= "ts_ls" then
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

          if client:supports_method("textDocument/documentHighlight") then
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

          -- automatically organize imports in golang
          if client.name == "gopls" then
            vim.api.nvim_create_autocmd({ "BufWritePre" }, {
              buffer = args.buf,
              group = vim.api.nvim_create_augroup("lsp_go_organize_imports", { clear = false }),
              callback = function()
                local params = vim.lsp.util.make_range_params(0, client.offset_encoding)
                params.context = {
                  only = { "source.organizeImports" }
                }

                local result = vim.lsp.buf_request_sync(args.buf, "textDocument/codeAction", params, 1000)
                for _, res in pairs(result or {}) do
                  for _, r in pairs(res.result or {}) do
                    if r.edit then
                      vim.lsp.util.apply_workspace_edit(r.edit, client.offset_encoding)
                    else
                      client:exec_cmd(r.command, { bufnr = args.buf })
                    end
                  end
                end
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

          if client:supports_method("textDocument/formatting") then
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

          if client:supports_method("textDocument/documentHighlight") then
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

        client:request("workspace/executeCommand", { command = "_ltex.checkDocument", arguments = { { uri = args.uri } } })
      end

      vim.keymap.set('n', 'K', function()
        vim.lsp.buf.hover({ max_width = 80 })
      end, { desc = 'Hover Documentation' })

      vim.keymap.set({ 'i' }, '<C-K>', function()
        vim.lsp.buf.signature_help({ max_width = 80 })
      end, { desc = 'Signature Help' })
    end
    -- }}}
  '';

  lsp = {
    inlayHints.enable = true;

    keymaps = [
      {
        key = "grf";
        lspBufAction = "format";
      }
    ];

    servers = {
      ltex_plus = {
        enable = true;
        package = pkgs.ltex-ls-plus;
        config.settings.ltex = {
          additionalRules = {
            motherTongue = "de-CH";
            enablePickyRules = true;
          };

          languageToolHttpServerUri = "https://api.languagetoolplus.com/";
        };
      };

      nixd = {
        enable = true;
        config.settings.nixd.formatting.command = [ (lib.getExe pkgs.nixfmt) ];
      };

      gopls = {
        enable = true;
        config = {
          settings.gopls.gofumpt = true;
          on_init = lib.nixvim.mkRaw ''
            function(client)
              local root_dir = client.root_dir or (client.config and client.config.root_dir)

              if root_dir and vim.uv.fs_stat(root_dir .. "/go.mod") then
                local res = vim.system({ "go", "list", "-m" }, {
                  cwd = root_dir,
                  text = true
                }):wait()

                if res.code == 0 then
                  client.settings = vim.tbl_deep_extend("force", client.settings or {}, {
                    gopls = { ["local"] = vim.trim(res.stdout) }
                  })
                  client:notify("workspace/didChangeConfiguration", { settings = client.settings })
                end
              end
            end
          '';
        };
      };

      ts_ls.enable = true;
      biome.enable = true;
      tailwindcss = {
        enable = true;
        config.settings.tailwindCSS.experimental.classRegex = [
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
        config.filetypes = [
          "c"
          "cpp"
          "objc"
          "objcpp"
          "cuda"
        ];
      };

      rust_analyzer.enable = true;

      sourcekit = {
        enable = true;
        package = if pkgs.stdenv.hostPlatform.isDarwin then null else pkgs.sourcekit-lsp;
        config = {
          capabilities.workspace.didChangeWatchedFiles.dynamicRegistration = true;
        }
        // lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
          cmd = [
            "xcrun"
            "sourcekit-lsp"
          ];
        };
      };
    };
  };

  plugins = {
    treesitter = {
      enable = true;
      folding.enable = true;

      grammarPackages = pkgs.vimPlugins.nvim-treesitter.passthru.allGrammars;

      settings = {
        highlight.enable = true;
        incremental_selection.enable = true;
        indent.enable = true;
      };
    };

    treesitter-context = {
      enable = true;
      settings.enable = false;
    };

    # provides default configs (cmd, filetypes, root markers) for `lsp.servers`
    lspconfig.enable = true;

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
