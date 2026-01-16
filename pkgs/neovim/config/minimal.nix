{ pkgs, lib, ... }:
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
    splitright = true;

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

  extraConfigLuaPre = lib.strings.concatStrings (
    [
      ''
        if vim.g.neovide then
          vim.o.guifont = "JetBrainsMono Nerd Font Mono:h14"
          vim.g.neovide_cursor_trail_size = 0
        end
      ''
    ]
    ++ lib.optionals pkgs.stdenv.isDarwin [
      ''
        if vim.trim(vim.fn.system("defaults read -g AppleInterfaceStyle")) == "Dark" then
          vim.opt.background = "dark"
        else
          vim.opt.background = "light"
        end
      ''
    ]
  );

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

    # search
    {
      key = "<leader>fp";
      mode = [ "n" ];
      action = "<cmd>FzfLua resume<cr>";
    }
    {
      key = "<leader>ff";
      mode = [ "n" ];
      action = "<cmd>FzfLua files<cr>";
    }
    {
      key = "<leader>fs";
      mode = [ "n" ];
      action = "<cmd>FzfLua live_grep<cr>";
    }
    {
      key = "<leader>fb";
      mode = [ "n" ];
      action = "<cmd>FzfLua buffers<cr>";
    }
    {
      key = "<leader>fh";
      mode = [ "n" ];
      action = "<cmd>FzfLua helptags<cr>";
    }
    {
      key = "<leader>fd";
      mode = [ "n" ];
      action = "<cmd>FzfLua diagnostics_workspace<cr>";
    }

    # resize pane
    {
      key = "<A-h>";
      mode = [ "n" ];
      action = "<cmd>vertical resize -10<cr>";
    }
    {
      key = "<A-j>";
      mode = [ "n" ];
      action = "<cmd>resize +10<cr>";
    }
    {
      key = "<A-k>";
      mode = [ "n" ];
      action = "<cmd>resize -10<cr>";
    }
    {
      key = "<A-l>";
      mode = [ "n" ];
      action = "<cmd>vertical resize +10<cr>";
    }
  ];

  colorschemes.catppuccin = {
    enable = true;
    settings = {
      flavour = "auto";
      background = {
        dark = "mocha";
        light = "latte";
      };

      integrations = {
        treesitter = true;

        fidget = true;
        gitsigns = true;
      };

      show_end_of_buffer = true;
      dim_inactive.enabled = true;
    };
  };

  autoCmd = [
    # highlight text on yank
    {
      event = [ "TextYankPost" ];
      command = "lua vim.hl.on_yank()";
    }
  ];

  extraPlugins = [
    pkgs.vimPlugins.plenary-nvim
    pkgs.vimPlugins.nui-nvim
  ];

  extraConfigVim = ''
    function! RemoveQFItem()
      let curqfidx = line('.') - 1
      let qfall = getqflist()
      call remove(qfall, curqfidx)
      call setqflist(qfall, 'r')
      execute curqfidx + 1 . "cfirst"
      :copen
    endfunction

    autocmd FileType qf map <buffer> dd <cmd>call RemoveQFItem()<cr>
  '';

  plugins = {
    lualine.enable = true;

    fzf-lua = {
      enable = true;
      settings.ui_select = true;
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

    web-devicons.enable = true;
  };
}
