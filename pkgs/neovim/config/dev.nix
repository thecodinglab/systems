{ pkgs, ... }:
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

  diagnostics.virtual_lines = {
    current_line = true;
  };

  keymaps = [
    {
      key = "<leader>d";
      mode = [ "n" ];
      action.__raw = ''
        function ()
          vim.diagnostic.enable(not vim.diagnostic.is_enabled())
        end
      '';
    }
  ];

  plugins = {
    lsp = {
      enable = true;
      inlayHints = true;

      preConfig = ''
        vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(
          vim.lsp.handlers.hover,
          {max_width = 80}
        )

        vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(
          vim.lsp.handlers.signature_help,
          {max_width = 80}
        )
      '';

      onAttach = ''
        if client.server_capabilities.documentFormattingProvider and client.name ~= "tsserver" and client.name ~= "ts_ls" then
          vim.api.nvim_create_autocmd({ "BufWritePre" }, {
            buffer = bufnr,
            group = vim.api.nvim_create_augroup("lsp_autoformat", { clear = false }),
            callback = function()
              vim.lsp.buf.format({ 
                bufnr = bufnr,
                async = false,
                timeout_ms = 150,
              })
            end,
          })
        end

        if client.server_capabilities.documentHighlightProvider then
          vim.api.nvim_create_autocmd({ "CursorHold" }, {
            buffer = bufnr,
            group = vim.api.nvim_create_augroup("lsp_document_highlight_hold", { clear = false }),
            callback = function()
              vim.lsp.buf.document_highlight()
            end,
          })

          vim.api.nvim_create_autocmd({ "CursorMoved" }, {
            buffer = bufnr,
            group = vim.api.nvim_create_augroup("lsp_document_highlight_moved", { clear = false }),
            callback = function()
              vim.lsp.buf.clear_references()
            end,
          })
        end
      '';

      keymaps.lspBuf = {
        "grf" = "format";
      };

      servers = {
        ltex = {
          enable = true;
          settings.additionalRules.motherTongue = "de-CH";
        };

        nixd = {
          enable = true;
          settings.formatting.command = [ (pkgs.lib.getExe' pkgs.nixfmt-rfc-style "nixfmt") ];
        };

        gopls = {
          enable = true;
          settings.gopls.gofumpt = true;

          extraOptions.on_new_config.__raw = ''
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

          onAttach.function = ''
            vim.api.nvim_create_autocmd({ "BufWritePre" }, {
              buffer = bufnr,
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

    trouble.enable = true;
    fidget.enable = true;

    telescope.keymaps = {
      "gd" = "lsp_definitions";
      "gi" = "lsp_implementations";
      "gD" = "lsp_type_definitions";

      "grr" = "lsp_references";
    };

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
