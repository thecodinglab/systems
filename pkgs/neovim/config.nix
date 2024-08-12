{ config, pkgs, ... }:
{
  options = {
    enable = pkgs.lib.mkEnableOption "enable nixvim configuration";
    enableGit = pkgs.lib.mkEnableOption "enable git integration";
    enableSpell = pkgs.lib.mkEnableOption "enable spell integration";
    enableObsidian = pkgs.lib.mkEnableOption "enable obsidian integration";
  };

  config = {
    inherit (config) enable;

    extraPackages = [ pkgs.ripgrep ];

    globals = {
      mapleader = " ";
      maplocalleader = " ";

      # disable netrw
      loaded_netrw = 1;
      loaded_netrwPlugin = 1;
    };

    opts = {
      fileencoding = "utf-8";
      spelllang = "en";

      # line handling
      number = true;
      relativenumber = true;
      scrolloff = 999;
      sidescrolloff = 8;
      wrap = false;

      cursorline = true;
      cursorlineopt = "number";

      # file backups
      backup = false;
      writebackup = false;
      swapfile = false;
      undofile = true;

      # indents
      expandtab = true;
      shiftwidth = 2;
      tabstop = 2;

      # other
      showmode = false;
      termguicolors = true;
      conceallevel = 2;

      mouse = "";
      shortmess = "IF";

      listchars = {
        eol = "¬";
        tab = "▸ ";
        trail = "×";
      };

      # set update time for lsp hover
      updatetime = 300;

      # t: auto wrap text
      # c: auto wrap comments
      # r: auto insert comment leader when hitting <enter> in insert mode
      # q: allow re-formatting comments
      # j: remove comment leader when joining lines
      formatoptions = "tcrqj";

      # folding
      foldlevel = 99;
      foldlevelstart = 99;
      foldenable = true;
    };

    keymaps = [
      # clear highlights
      {
        key = "<ESC>";
        mode = [ "n" ];
        action = "<cmd>noh<cr>";
      }

      # stay in visual mode after changing indentation
      {
        key = ">";
        mode = [ "v" ];
        action = ">gv";
      }
      {
        key = "<";
        mode = [ "v" ];
        action = "<gv";
      }

      # copy to system clipboard
      {
        key = "<leader>y";
        mode = [
          "n"
          "v"
        ];
        action = "\"+y";
      }

      # open file explorer
      {
        key = "-";
        mode = [ "n" ];
        action = "<cmd>Oil<cr>";
      }

      # prettier
      {
        key = "gp";
        action = "<cmd>%!npx prettier --stdin-filepath %<cr>";
      }
    ];

    colorschemes.catppuccin = {
      enable = true;
      settings = {
        flavour = "mocha";
        integrations = {
          cmp = true;
          treesitter = true;

          fidget = true;
          gitsigns = true;
        };
      };
    };

    autoCmd = [
      # highlight text on yank
      {
        event = [ "TextYankPost" ];
        command = "lua vim.highlight.on_yank()";
      }
    ];

    extraPlugins = [
      pkgs.vimPlugins.plenary-nvim
      pkgs.vimPlugins.nui-nvim
    ];

    plugins = {
      treesitter = {
        enable = true;
        folding = true;
        settings = {
          highlight.enable = true;
          indent.enable = true;
        };
      };

      lsp = {
        enable = true;
        inlayHints = true;

        onAttach = ''
          if client.server_capabilities.documentFormattingProvider and client.name ~= "tsserver" then
            vim.api.nvim_create_autocmd({ "BufWritePre" }, {
              buffer = bufnr,
              group = vim.api.nvim_create_augroup("lsp_autoformat", { clear = false }),
              callback = function()
                vim.lsp.buf.format({ bufnr = bufnr, async = false, timeout_ms = 150 })
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
          K = "hover";
          "<leader>rn" = "rename";
          "<leader>ca" = "code_action";
        };

        servers = {
          ltex.enable = true;

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
                        vim.lsp.util.apply_workspace_edit(r.edit, "UTF-8")
                      else
                        vim.lsp.buf.execute_command(r.command)
                      end
                    end
                  end
                end,
              })
            '';
          };

          tsserver.enable = true;
          eslint.enable = true;

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

          rust-analyzer = {
            enable = true;
            installCargo = false;
            installRustc = false;
          };

          hls.enable = true;
          texlab.enable = true;
        };
      };

      lightline = {
        enable = true;
        colorscheme = "catppuccin";
      };

      trouble.enable = true;
      fidget.enable = true;

      cmp = {
        enable = true;
        settings = {
          preselect = "none";

          experimental = {
            ghost_text = true;
          };

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
            { name = "path"; }
            { name = "buffer"; }
          ];
        };
      };

      telescope = {
        enable = true;
        extensions = {
          fzf-native.enable = true;
          ui-select.enable = true;
        };
        keymaps = {
          "gd" = "lsp_definitions";
          "gr" = "lsp_references";
          "gi" = "lsp_implementations";
          "gt" = "lsp_type_definitions";

          "<leader>fp" = "previous";
          "<leader>ff" = "find_files";
          "<leader>fb" = "buffers";
          "<leader>fh" = "help_tags";
          "<leader>fd" = "diagnostics";
          "<leader>fg" = "git_branches";
          "<leader>fc" = "git_commits";
          "<leader>fC" = "git_bcommits";
        };
      };

      oil = {
        enable = true;
        settings = {
          default_file_explorer = true;
          skip_confirm_for_simple_edits = true;
        };
      };

      surround.enable = true;
      undotree.enable = true;
      hardtime.enable = true;

      tmux-navigator = {
        enable = true;
        keymaps = [
          {
            action = "left";
            key = "<C-w>h";
          }
          {
            action = "down";
            key = "<C-w>j";
          }
          {
            action = "up";
            key = "<C-w>k";
          }
          {
            action = "right";
            key = "<C-w>l";
          }
        ];
      };

      gitsigns.enable = config.enableGit;
      lazygit.enable = config.enableGit;

      vimtex.enable = true;
      ledger.enable = true;

      obsidian = {
        enable = config.enableObsidian;
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
              if vim.fn.executable("xdg-open") then
                vim.fn.jobstart({ "xdg-open", url })
                return
              end

              if vim.fn.executable("open") then
                vim.fn.jobstart({ "open", url })
                return
              end

              vim.notify("unable to open link: no tool found", vim.log.levels.ERROR)
            end
          '';
        };
      };
    };
  };
}
