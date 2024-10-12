{ pkgs, ... }:
{
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
    updatetime = 100;

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

    # resize pane
    {
      key = "<cs-h>";
      mode = [ "n" ];
      action = "<cmd>vertical resize -10<cr>";
    }
    {
      key = "<cs-j>";
      mode = [ "n" ];
      action = "<cmd>resize +10<cr>";
    }
    {
      key = "<cs-k>";
      mode = [ "n" ];
      action = "<cmd>resize -10<cr>";
    }
    {
      key = "<cs-l>";
      mode = [ "n" ];
      action = "<cmd>vertical resize +10<cr>";
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

    # disable syntax highlight on large files
    # inspired by https://github.com/LunarVim/bigfile.nvim/blob/33eb067e3d7029ac77e081cfe7c45361887a311a/lua/bigfile/features.lua
    {
      event = [ "BufReadPre" ];
      callback.__raw = ''
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
  ];

  extraPlugins = [
    pkgs.vimPlugins.plenary-nvim
    pkgs.vimPlugins.nui-nvim
  ];

  plugins = {
    treesitter = {
      enable = true;
      folding = true;
      settings =
        builtins.mapAttrs
          (
            name: value:
            value
            // {
              disable.__raw = ''
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

    lualine.enable = true;

    telescope = {
      enable = true;
      extensions = {
        fzf-native.enable = true;
        ui-select.enable = true;
      };
      keymaps = {
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

    vim-surround.enable = true;
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

    mini = {
      enable = true;
      mockDevIcons = true;
      modules = {
        icons = { };
      };
    };
  };
}
