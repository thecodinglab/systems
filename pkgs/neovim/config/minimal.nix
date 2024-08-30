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

    lightline = {
      enable = true;
      settings.colorscheme = "catppuccin";
    };

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
  };
}
