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
    ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
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

  # The palette the rest of the system is drawn in (see the theme module) as
  # a colorscheme of its own: neovim reloads the loaded colorscheme whenever
  # 'background' changes, so it takes the light or the dark half from the
  # background detected above, and again when the terminal reports another.
  extraFiles."colors/system.lua".text = ''
    local palettes = vim.json.decode([[${
      builtins.toJSON (
        lib.mapAttrs (_: lib.mapAttrs (_: hex: "#${hex}")) (
          removeAttrs (import ../../../modules/home-manager/theme/palette.nix) [ "selection" ]
        )
      )
    }]])
    local selections = vim.json.decode([[${
      builtins.toJSON (
        lib.mapAttrs (_: hex: "#${hex}") (import ../../../modules/home-manager/theme/palette.nix).selection
      )
    }]])
    local appearance = palettes[vim.o.background] and vim.o.background or "dark"
    local p = palettes[appearance]

    vim.cmd.highlight("clear")
    vim.g.colors_name = "system"

    local function mix(from, to, amount)
      local out = "#"
      for i = 2, 6, 2 do
        local a, b = tonumber(from:sub(i, i + 1), 16), tonumber(to:sub(i, i + 1), 16)
        out = out .. string.format("%02x", math.floor(a + (b - a) * amount + 0.5))
      end
      return out
    end

    -- the tiers, see the palette
    local ground, raised, rule = p.base00, p.base01, p.base02
    local dim, muted, ink, strong = p.base03, p.base04, p.base05, p.base06
    local red, orange, amber, green = p.base08, p.base09, p.base0A, p.base0B
    local cyan, blue, purple = p.base0C, p.base0D, p.base0E

    -- Quiet Colour: what you wrote is in the ink, comments and punctuation
    -- in the grey, operators a step toward it. Each kind of word the
    -- language supplies has a hue: keywords purple, functions blue, types
    -- cyan, strings green, numbers and constants amber. Builtins keep the
    -- strong ink. Red is an error and orange a warning, never syntax.
    local groups = {
      Normal = { fg = ink, bg = ground },
      NormalNC = { link = "Normal" },
      NormalFloat = { fg = ink, bg = raised },
      FloatBorder = { fg = dim, bg = raised },
      FloatTitle = { fg = strong, bg = raised, bold = true },
      Pmenu = { fg = ink, bg = raised },
      PmenuSel = { fg = strong, bg = rule, bold = true },
      PmenuMatch = { fg = strong, bold = true },
      PmenuMatchSel = { fg = strong, bg = rule, bold = true },
      PmenuSbar = { bg = raised },
      PmenuThumb = { bg = dim },

      CursorLine = { bg = raised },
      CursorColumn = { bg = raised },
      ColorColumn = { bg = raised },
      CursorLineNr = { fg = strong, bg = raised },
      LineNr = { fg = dim },
      SignColumn = { fg = dim },
      FoldColumn = { fg = dim },
      Folded = { fg = dim, bg = raised },
      EndOfBuffer = { fg = ground },
      NonText = { fg = dim },
      Whitespace = { fg = rule },
      SpecialKey = { fg = dim },
      Conceal = { fg = dim },

      Visual = { bg = selections[appearance] },
      VisualNOS = { link = "Visual" },
      -- found text is a signal, so it is the one ground laid in a hue
      Search = { fg = ground, bg = amber },
      CurSearch = { fg = ground, bg = orange, bold = true },
      IncSearch = { link = "CurSearch" },
      Substitute = { link = "CurSearch" },
      MatchParen = { bg = rule, bold = true },
      QuickFixLine = { bg = raised, bold = true },

      -- splits are told apart by a quiet line, the comment grey, like the
      -- border round the active tmux pane
      WinSeparator = { fg = dim },
      StatusLine = { fg = ink, bg = raised },
      StatusLineNC = { fg = dim, bg = raised },
      TabLine = { fg = dim, bg = raised },
      TabLineFill = { bg = raised },
      TabLineSel = { fg = strong, bg = ground, bold = true },
      WinBar = { fg = ink, bold = true },
      WinBarNC = { fg = dim },

      Title = { fg = strong, bold = true },
      Directory = { fg = strong },
      ModeMsg = { fg = strong, bold = true },
      MoreMsg = { fg = ink },
      Question = { fg = ink },
      OkMsg = { fg = green },
      ErrorMsg = { fg = red },
      WarningMsg = { fg = orange },

      Comment = { fg = dim, italic = true },
      Constant = { fg = amber },
      String = { fg = green },
      Character = { link = "String" },
      Number = { fg = amber },
      Boolean = { fg = amber },
      Float = { fg = amber },
      Identifier = { fg = ink },
      Function = { fg = blue },
      Statement = { fg = purple },
      Keyword = { link = "Statement" },
      Conditional = { link = "Statement" },
      Repeat = { link = "Statement" },
      Label = { link = "Statement" },
      Exception = { link = "Statement" },
      Operator = { fg = muted },
      PreProc = { fg = dim },
      Include = { link = "Statement" },
      Define = { link = "Statement" },
      Macro = { link = "Function" },
      Type = { fg = cyan },
      StorageClass = { link = "Statement" },
      Structure = { link = "Statement" },
      Typedef = { link = "Statement" },
      Special = { fg = strong },
      SpecialChar = { fg = amber },
      Tag = { fg = blue },
      Delimiter = { fg = dim },
      Debug = { fg = dim },
      Underlined = { underline = true },
      Error = { fg = red },
      Todo = { fg = strong, bold = true },

      ["@variable"] = { fg = ink },
      ["@variable.builtin"] = { fg = strong, italic = true },
      ["@variable.parameter"] = { fg = ink },
      ["@variable.member"] = { fg = ink },
      ["@property"] = { fg = ink },
      ["@module"] = { fg = ink },
      ["@constant"] = { link = "Constant" },
      ["@constant.builtin"] = { link = "Constant" },
      ["@string"] = { link = "String" },
      ["@string.escape"] = { link = "SpecialChar" },
      ["@string.special"] = { link = "SpecialChar" },
      ["@type"] = { link = "Type" },
      ["@type.builtin"] = { link = "Type" },
      ["@attribute"] = { fg = dim },
      ["@function"] = { link = "Function" },
      ["@function.builtin"] = { link = "Function" },
      ["@constructor"] = { link = "Type" },
      ["@operator"] = { link = "Operator" },
      ["@keyword"] = { link = "Statement" },
      ["@punctuation"] = { link = "Delimiter" },
      ["@punctuation.special"] = { fg = amber },
      ["@tag"] = { link = "Tag" },
      ["@tag.attribute"] = { fg = ink },
      ["@tag.delimiter"] = { link = "Delimiter" },
      ["@comment"] = { link = "Comment" },
      ["@comment.error"] = { fg = red, bold = true },
      ["@comment.warning"] = { fg = orange, bold = true },
      ["@comment.todo"] = { link = "Todo" },
      ["@comment.note"] = { fg = blue, bold = true },
      ["@markup.heading"] = { link = "Title" },
      ["@markup.strong"] = { bold = true },
      ["@markup.italic"] = { italic = true },
      ["@markup.strikethrough"] = { strikethrough = true },
      ["@markup.link"] = { fg = blue },
      ["@markup.link.url"] = { fg = blue, underline = true },
      ["@markup.raw"] = { fg = green },
      ["@markup.quote"] = { fg = dim, italic = true },
      ["@markup.list"] = { fg = dim },
      ["@diff.plus"] = { fg = green },
      ["@diff.minus"] = { fg = red },
      ["@diff.delta"] = { fg = orange },

      Added = { fg = green },
      Changed = { fg = orange },
      Removed = { fg = red },
      DiffAdd = { bg = mix(ground, green, 0.16) },
      DiffChange = { bg = mix(ground, blue, 0.10) },
      DiffText = { bg = mix(ground, blue, 0.28) },
      DiffDelete = { fg = mix(ground, red, 0.5), bg = mix(ground, red, 0.12) },

      DiagnosticError = { fg = red },
      DiagnosticWarn = { fg = orange },
      DiagnosticInfo = { fg = blue },
      DiagnosticHint = { fg = dim },
      DiagnosticOk = { fg = green },
      DiagnosticUnderlineError = { undercurl = true, sp = red },
      DiagnosticUnderlineWarn = { undercurl = true, sp = orange },
      DiagnosticUnderlineInfo = { undercurl = true, sp = blue },
      DiagnosticUnderlineHint = { undercurl = true, sp = dim },
      DiagnosticUnderlineOk = { undercurl = true, sp = green },
      DiagnosticUnnecessary = { fg = dim },
      DiagnosticDeprecated = { strikethrough = true },
      SpellBad = { undercurl = true, sp = red },
      SpellCap = { undercurl = true, sp = orange },
      SpellLocal = { undercurl = true, sp = blue },
      SpellRare = { undercurl = true, sp = blue },

      LspReferenceText = { bg = rule },
      LspReferenceRead = { bg = rule },
      LspReferenceWrite = { bg = rule, bold = true },
      LspInlayHint = { fg = dim, italic = true },
      LspSignatureActiveParameter = { bold = true, underline = true },

      -- fzf-lua picks named X11 colours of its own (CadetBlue1, LightGreen,
      -- PaleVioletRed1...) for anything not linked to a standard group;
      -- these are context, so the grey, and what you act on the strong ink
      FzfLuaHeaderBind = { fg = strong, bold = true },
      FzfLuaHeaderText = { fg = dim },
      FzfLuaPathColNr = { fg = dim },
      FzfLuaPathLineNr = { fg = dim },
      FzfLuaLivePrompt = { fg = strong },
      FzfLuaLiveSym = { fg = strong },
      FzfLuaBufNr = { fg = dim },
      FzfLuaBufFlagCur = { fg = strong, bold = true },
      FzfLuaBufFlagAlt = { fg = dim },
      FzfLuaTabTitle = { fg = strong, bold = true },
      FzfLuaTabMarker = { fg = strong, bold = true },
    }

    -- let the terminal's translucency show through the editor
    if vim.env.TERMINAL_BACKGROUND_TRANSPARENT == "1" then
      groups.Normal.bg = nil
      groups.EndOfBuffer.fg = nil
    end

    for name, spec in pairs(groups) do
      vim.api.nvim_set_hl(0, name, spec)
    end

    -- :terminal in the same sixteen colours as the terminal around it
    for index, slot in ipairs({
      "base00", "base08", "base0B", "base0A", "base0D", "base0E", "base0C", "base05",
      "base03", "base08", "base0B", "base0A", "base0D", "base0E", "base0C", "base07",
    }) do
      vim.g["terminal_color_" .. (index - 1)] = p[slot]
    end
  '';
  colorscheme = "system";

  extraConfigLua = ''
    -- tmux-navigator only knows tmux, inside herdr move to the herdr pane
    -- next to the editor once there is no split left in that direction
    if vim.env.HERDR_ENV == "1" and vim.env.TMUX == nil then
      vim.g.tmux_navigator_no_mappings = 1
      for key, direction in pairs({ h = "left", j = "down", k = "up", l = "right" }) do
        local function navigate()
          local win = vim.api.nvim_get_current_win()
          vim.cmd.wincmd(key)
          if vim.api.nvim_get_current_win() == win then
            vim.system({ vim.env.HERDR_BIN_PATH or "herdr", "pane", "focus", "--direction", direction, "--current" })
          end
        end
        vim.keymap.set("n", "<C-" .. key .. ">", navigate, { silent = true })
        vim.keymap.set("n", "<C-w>" .. key, navigate, { silent = true })
      end
    end
  '';

  autoCmd = [
    # highlight text on yank
    {
      event = [ "TextYankPost" ];
      callback = lib.nixvim.mkRaw ''
        function()
          vim.hl.on_yank()
        end
      '';
    }

    # remove quickfix entries with `dd`
    {
      event = [ "FileType" ];
      pattern = [ "qf" ];
      callback = lib.nixvim.mkRaw ''
        function(args)
          vim.keymap.set("n", "dd", function()
            local idx = vim.fn.line(".")
            local items = vim.fn.getqflist()
            table.remove(items, idx)
            vim.fn.setqflist(items, "r")
            if #items > 0 then
              vim.cmd(math.min(idx, #items) .. "cfirst")
              vim.cmd.copen()
            end
          end, { buffer = args.buf })
        end
      '';
    }
  ];

  plugins = {
    lualine = {
      enable = true;
      settings = {
        options = {
          icons_enabled = false;
          theme = "auto";
          # square boxes instead of angled powerline separators
          component_separators = "";
          section_separators = "";
          globalstatus = true;
        };
        sections = {
          lualine_a = [ "mode" ];
          lualine_b = [ "branch" ];
          lualine_c = [ "filename" ];
          lualine_x = [ "diagnostics" ];
          lualine_y = [ "filetype" ];
          lualine_z = [ "location" ];
        };
        inactive_sections = {
          lualine_a = [ ];
          lualine_b = [ ];
          lualine_c = [ "filename" ];
          lualine_x = [ "location" ];
          lualine_y = [ ];
          lualine_z = [ ];
        };
      };
    };

    fzf-lua = {
      enable = true;
      settings.ui_select = { };
    };

    oil = {
      enable = true;
      settings = {
        default_file_explorer = true;
        skip_confirm_for_simple_edits = true;
      };
    };

    nvim-surround.enable = true;
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

    # file icons in the ink of whatever they sit in rather than one colour
    # per language, in the finder, the file browser and the status line
    web-devicons = {
      enable = true;
      settings.color_icons = false;
    };
  };
}
