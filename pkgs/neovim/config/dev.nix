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

  plugins = {
    lsp = {
      enable = true;
      inlayHints = true;

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

      keymaps = {
        lspBuf = {
          K = "hover";
          "grn" = "rename";
          "gra" = "code_action";
          "grf" = "format";
        };

        extra = [
          {
            key = "<C-S>";
            action = "<cmd>lua vim.lsp.buf.signature_help()<cr>";
            mode = [ "i" ];
          }
        ];
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
        eslint.enable = true;
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

        hls.enable = true;
        texlab.enable = true;

        yamlls = {
          enable = true;
          settings = {
            format = {
              enable = true;
              printWidth = 80;
            };
            schemas = {
              kubernetes = "*.yaml";
              "https://json.schemastore.org/kustomization" = "/kustomization.yaml";
            };
          };
        };
      };
    };

    trouble.enable = true;
    fidget.enable = true;

    cmp = {
      enable = true;
      autoEnableSources = false;
      settings = {
        preselect = "none";

        experimental = {
          ghost_text = true;
        };

        snippet.expand = ''
          function(args)
            vim.fn["vsnip#anonymous"](args.body)
          end
        '';

        mapping = {
          "<C-d>" = "cmp.mapping.scroll_docs(-4)";
          "<C-f>" = "cmp.mapping.scroll_docs(4)";

          "<C-e>" = "cmp.mapping.close()";
          "<C-c>" = "cmp.mapping.abort()";

          "<C-y>" = "cmp.mapping.confirm({ select = true })";
          "<C-p>" = "cmp.mapping(cmp.mapping.select_prev_item(), {'i', 's'})";
          "<C-n>" = "cmp.mapping(cmp.mapping.select_next_item(), {'i', 's'})";
        };

        formatting = {
          fields = [
            "abbr"
            "kind"
            "menu"
          ];
        };

        sources = [
          { name = "nvim_lsp"; }
          { name = "vsnip"; }
          { name = "path"; }
          { name = "buffer"; }
        ];
      };
    };

    cmp-nvim-lsp.enable = true;
    cmp-path.enable = true;
    cmp-buffer.enable = true;
    cmp-vsnip.enable = true;
    friendly-snippets.enable = true;

    telescope.keymaps = {
      "gd" = "lsp_definitions";
      "gi" = "lsp_implementations";
      "gD" = "lsp_type_definitions";

      "grr" = "lsp_references";
    };

    gitsigns.enable = true;
    lazygit.enable = true;

    vimtex = {
      enable = true;
      texlivePackage = pkgs.texlive.combined.scheme-full;
      settings.view_method = if pkgs.stdenv.isDarwin then "sioyek" else "zathura";
    };
    ledger.enable = true;
    markdown-preview.enable = true;

    obsidian = {
      enable = true;
      settings = {
        dir = "~/vaults/singularity";

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

        note_id_func = ''
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

        follow_url_func = ''
          function(url)
            if vim.fn.executable("xdg-open") == 1 then
              vim.fn.jobstart({ "xdg-open", url })
              return
            end

            if vim.fn.executable("open") == 1 then
              vim.fn.jobstart({ "open", url })
              return
            end

            vim.notify("unable to open link: no tool found", vim.log.levels.ERROR)
          end
        '';
      };
    };
  };
}
