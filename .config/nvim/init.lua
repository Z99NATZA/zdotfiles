-- Basic editor settings
vim.g.mapleader = "\\"
vim.g.maplocalleader = "\\"

-- Keep the directory Neovim was launched from as the sidebar boundary.
local nvim_startup_cwd = vim.fn.getcwd()

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.cursorline = true
vim.opt.mouse = "a"
vim.opt.clipboard = "unnamedplus"
vim.opt.termguicolors = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.updatetime = 250
vim.opt.timeoutlen = 400
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.wrap = false
vim.opt.signcolumn = "yes"
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
vim.opt.expandtab = true

vim.api.nvim_create_autocmd("FileType", {
  pattern = "make",
  callback = function()
    vim.opt_local.tabstop = 4
    vim.opt_local.shiftwidth = 4
    vim.opt_local.softtabstop = 4
    vim.opt_local.expandtab = false
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "qf",
  callback = function(args)
    vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = args.buf, silent = true, desc = "Close list" })
    vim.keymap.set("n", "<Esc>", "<cmd>close<CR>", { buffer = args.buf, silent = true, desc = "Close list" })
  end,
})

-- Keymaps
local map = vim.keymap.set

map({ "n", "x" }, "<C-j>", "5j", { desc = "Move down 5 lines" })
map({ "n", "x" }, "<C-k>", "5k", { desc = "Move up 5 lines" })
map("i", "kj", "<Esc>", { desc = "Exit insert mode" })
map("i", "<C-BS>", "<C-w>", { desc = "Delete previous word" })
-- Most terminals encode Ctrl+Backspace as Ctrl-H rather than a distinct key.
map("i", "<C-h>", "<C-w>", { desc = "Delete previous word" })

map("n", "<M-j>", "<cmd>move .+1<CR>==", { desc = "Move line down" })
map("n", "<M-k>", "<cmd>move .-2<CR>==", { desc = "Move line up" })
map("x", "<M-j>", ":move '>+1<CR>gv=gv", { desc = "Move selection down" })
map("x", "<M-k>", ":move '<-2<CR>gv=gv", { desc = "Move selection up" })

-- Switch focus without closing the sidebar or losing the previous editor split.
local function toggle_sidebar_focus()
  local api = require("nvim-tree.api")
  local current = vim.api.nvim_get_current_win()
  local function is_editor(win)
    if not win or not vim.api.nvim_win_is_valid(win) then
      return false
    end
    local buf = vim.api.nvim_win_get_buf(win)
    return vim.api.nvim_win_get_tabpage(win) == vim.api.nvim_get_current_tabpage()
      and vim.api.nvim_win_get_config(win).relative == ""
      and vim.bo[buf].buftype == ""
      and vim.bo[buf].filetype ~= "NvimTree"
  end

  vim.cmd.stopinsert()
  if vim.bo.filetype == "NvimTree" then
    local target = vim.t.sidebar_editor_win
    if not is_editor(target) then
      target = nil
      for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        if is_editor(win) then
          target = win
          break
        end
      end
    end
    if target then
      vim.api.nvim_set_current_win(target)
    else
      vim.cmd("rightbelow vnew")
    end
  else
    if is_editor(current) then
      vim.t.sidebar_editor_win = current
    end
    api.tree.open({ focus = true })
  end
end

map({ "n", "i", "x", "t" }, "<C-0>", toggle_sidebar_focus, {
  silent = true,
  desc = "Switch focus between sidebar and editor",
})

local function copy_file_path(path)
  if type(path) ~= "string" or path == "" then
    vim.notify("No file path to copy", vim.log.levels.WARN)
    return
  end

  local absolute_path = vim.fs.normalize(vim.fn.fnamemodify(path, ":p"))
  vim.fn.setreg("+", absolute_path)
  vim.fn.setreg('"', absolute_path)
  vim.notify("Copied path: " .. absolute_path)
end

local function copy_context_file_path()
  if vim.bo.filetype == "NvimTree" then
    local node = require("nvim-tree.api").tree.get_node_under_cursor()
    copy_file_path(node and node.absolute_path)
    return
  end

  copy_file_path(vim.api.nvim_buf_get_name(0))
end

local function copy_telescope_file_path()
  local entry = require("telescope.actions.state").get_selected_entry()
  copy_file_path(entry and (entry.path or entry.filename or entry.value))
end

map("n", "<leader>e", ":e ", { desc = "Edit file" })
map("n", "<leader>rs", "<cmd>restart<CR>", { desc = "Restart Neovim and reload config" })
map("n", "<leader>cp", copy_context_file_path, { desc = "Copy file path" })
map("n", "<leader>w", "<cmd>write<CR>", { desc = "Save file" })
map("n", "<leader>df", "<cmd>wall<CR><cmd>qall<CR>", { desc = "Save all files and quit Neovim" })

-- Persistent terminal panel at the bottom, similar to VS Code.
local terminal_bufnr
local terminal_winid
local terminal_height = 12

local SIDEBAR_MIN_WIDTH = 20
local SIDEBAR_MAX_WIDTH = 80
local TERMINAL_MIN_HEIGHT = 5
local TERMINAL_MAX_HEIGHT = 30

local function toggle_terminal()
  if terminal_winid and vim.api.nvim_win_is_valid(terminal_winid) then
    vim.api.nvim_win_hide(terminal_winid)
    terminal_winid = nil
    return
  end

  -- When invoked from the sidebar, place the panel below the editor instead
  -- of splitting the sidebar itself.
  if vim.bo.filetype == "NvimTree" then
    for _, winid in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      local bufnr = vim.api.nvim_win_get_buf(winid)
      if vim.bo[bufnr].filetype ~= "NvimTree" and vim.bo[bufnr].buftype ~= "terminal" then
        vim.api.nvim_set_current_win(winid)
        break
      end
    end
  end

  vim.cmd("belowright " .. terminal_height .. "new")
  terminal_winid = vim.api.nvim_get_current_win()

  if terminal_bufnr and vim.api.nvim_buf_is_valid(terminal_bufnr) then
    vim.api.nvim_win_set_buf(terminal_winid, terminal_bufnr)
  else
    vim.cmd("terminal")
    terminal_bufnr = vim.api.nvim_get_current_buf()
    vim.bo[terminal_bufnr].buflisted = false

    vim.api.nvim_create_autocmd("TermClose", {
      buffer = terminal_bufnr,
      once = true,
      callback = function()
        local closed_bufnr = terminal_bufnr
        local closed_winid = terminal_winid
        terminal_bufnr = nil
        terminal_winid = nil

        vim.schedule(function()
          if closed_winid and vim.api.nvim_win_is_valid(closed_winid) then
            vim.api.nvim_win_close(closed_winid, true)
          end
          if closed_bufnr and vim.api.nvim_buf_is_valid(closed_bufnr) then
            vim.api.nvim_buf_delete(closed_bufnr, { force = true })
          end
        end)
      end,
    })
  end

  vim.wo[terminal_winid].number = false
  vim.wo[terminal_winid].relativenumber = false
  vim.wo[terminal_winid].signcolumn = "no"
  vim.wo[terminal_winid].winfixheight = true
  vim.cmd("startinsert")
end

vim.api.nvim_create_user_command("ToggleTerminal", toggle_terminal, {})

local function validated_panel_size(fargs, flag, hint, minimum, maximum)
  if #fargs ~= 2 or fargs[1] ~= flag or not fargs[2]:match("^[+-]?%d+$") then
    vim.api.nvim_echo({ { hint, "WarningMsg" } }, true, {})
    return nil
  end

  return math.min(maximum, math.max(minimum, tonumber(fargs[2])))
end

vim.api.nvim_create_user_command("Sidebar", function(args)
  local width = validated_panel_size(
    args.fargs,
    "-w",
    "Do you mean :Sidebar -w {number}",
    SIDEBAR_MIN_WIDTH,
    SIDEBAR_MAX_WIDTH
  )
  if not width then
    return
  end

  require("nvim-tree.api").tree.resize({ width = width })
  vim.api.nvim_echo({ { "Sidebar width: " .. width, "Normal" } }, false, {})
end, {
  nargs = "*",
  complete = function(arglead)
    return vim.startswith("-w", arglead) and { "-w" } or {}
  end,
})

local function resize_sidebar(step)
  local tree = require("nvim-tree.api").tree
  local winid = tree.winid()
  if not winid then
    return
  end

  local current_width = vim.api.nvim_win_get_width(winid)
  local next_width = math.max(SIDEBAR_MIN_WIDTH, math.min(SIDEBAR_MAX_WIDTH, current_width + step))
  if next_width ~= current_width then
    tree.resize({ absolute = next_width })
  end
end

map({ "n", "i", "x", "t" }, "<D-,>", function()
  resize_sidebar(-2)
end, { desc = "Shrink sidebar" })
map({ "n", "i", "x", "t" }, "<D-.>", function()
  resize_sidebar(2)
end, { desc = "Expand sidebar" })

vim.api.nvim_create_user_command("Terminal", function(args)
  local height = validated_panel_size(
    args.fargs,
    "-h",
    "Do you mean :Terminal -h {number}",
    TERMINAL_MIN_HEIGHT,
    TERMINAL_MAX_HEIGHT
  )
  if not height then
    return
  end

  terminal_height = height
  if terminal_winid and vim.api.nvim_win_is_valid(terminal_winid) then
    vim.api.nvim_win_set_height(terminal_winid, terminal_height)
  end
  vim.api.nvim_echo({ { "Terminal height: " .. height, "Normal" } }, false, {})
end, {
  nargs = "*",
  complete = function(arglead)
    return vim.startswith("-h", arglead) and { "-h" } or {}
  end,
})

local function resize_terminal(step)
  if not terminal_winid or not vim.api.nvim_win_is_valid(terminal_winid) then
    return
  end

  local current_height = vim.api.nvim_win_get_height(terminal_winid)
  local next_height = math.max(TERMINAL_MIN_HEIGHT, math.min(TERMINAL_MAX_HEIGHT, current_height + step))
  if next_height ~= current_height then
    vim.api.nvim_win_set_height(terminal_winid, next_height)
    terminal_height = vim.api.nvim_win_get_height(terminal_winid)
  end
end

map({ "n", "i", "x", "t" }, "<D-->", function()
  resize_terminal(-2)
end, { desc = "Shrink terminal panel" })
map({ "n", "i", "x", "t" }, "<D-=>", function()
  resize_terminal(2)
end, { desc = "Expand terminal panel" })

-- Ctrl+` is encoded as Ctrl+@ / Ctrl+Space by terminals that do not support
-- extended keyboard reporting. Map every representation to the same action.
for _, lhs in ipairs({ "<C-`>", "<C-@>", "<C-Space>" }) do
  map("n", lhs, toggle_terminal, { desc = "Toggle terminal panel" })
  map("i", lhs, "<Esc><cmd>ToggleTerminal<CR>", { desc = "Toggle terminal panel" })
  map("x", lhs, "<Esc><cmd>ToggleTerminal<CR>", { desc = "Toggle terminal panel" })
  map("t", lhs, [[<C-\><C-n><cmd>ToggleTerminal<CR>]], { desc = "Toggle terminal panel" })
end

map("n", "K", function()
  if #vim.lsp.get_clients({ bufnr = 0 }) > 0 then
    vim.lsp.buf.hover({ border = "rounded" })
  else
    vim.diagnostic.open_float(nil, { border = "rounded", focus = false })
  end
end, { desc = "Show hint/documentation" })

-- Rust language server (provides hover documentation, diagnostics, and more)
vim.lsp.config("rust_analyzer", {
  cmd = { "rust-analyzer" },
  filetypes = { "rust" },
  root_markers = { "Cargo.toml", "rust-project.json", ".git" },
  settings = {
    ["rust-analyzer"] = {
      inlayHints = {
        chainingHints = { enable = true },
        parameterHints = { enable = true },
        typeHints = {
          enable = true,
          hideClosureInitialization = false,
          hideNamedConstructor = false,
        },
      },
    },
  },
})

-- Python language server (hover, diagnostics, completion, and inlay hints)
vim.lsp.config("basedpyright", {
  cmd = { "basedpyright-langserver", "--stdio" },
  filetypes = { "python" },
  root_markers = { "pyproject.toml", "pyrightconfig.json", "requirements.txt", ".git" },
  settings = {
    basedpyright = {
      analysis = {
        diagnosticMode = "openFilesOnly",
        inlayHints = {
          variableTypes = true,
          callArgumentNames = true,
          callArgumentNamesMatching = true,
          functionReturnTypes = true,
          genericTypes = true,
        },
      },
    },
  },
})

-- Load and enable inlay hints before the language server attaches so its first
-- didOpen notification is not missed.
vim.lsp.inlay_hint.enable(true)
vim.lsp.enable("rust_analyzer")
vim.lsp.enable("basedpyright")

-- Refresh again after a language server has indexed the workspace. Its first
-- inlay-hint response can be empty while project loading is still in progress.
local inlay_hint_group = vim.api.nvim_create_augroup("lsp-inlay-hints", { clear = true })

local function refresh_inlay_hints(bufnr)
  if vim.api.nvim_buf_is_valid(bufnr) then
    vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
  end
end

vim.api.nvim_create_autocmd("LspAttach", {
  group = inlay_hint_group,
  callback = function(args)
    map("n", "gd", vim.lsp.buf.definition, { buffer = args.buf, desc = "Go to definition" })
    map("n", "gr", vim.lsp.buf.references, { buffer = args.buf, desc = "Show references" })

    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client and client:supports_method("textDocument/inlayHint") then
      refresh_inlay_hints(args.buf)
      vim.defer_fn(function()
        refresh_inlay_hints(args.buf)
      end, 3000)
    end
  end,
})

vim.api.nvim_create_autocmd("LspProgress", {
  group = inlay_hint_group,
  pattern = "end",
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client and client:supports_method("textDocument/inlayHint") then
      for bufnr in pairs(client.attached_buffers) do
        refresh_inlay_hints(bufnr)
      end
    end
  end,
})

-- Plugin manager
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local result = vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "--branch=stable",
    "https://github.com/folke/lazy.nvim.git",
    lazypath,
  })
  if vim.v.shell_error ~= 0 then
    error("Could not install lazy.nvim:\n" .. result)
  end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  {
    "sonph/onehalf",
    lazy = false,
    priority = 1000,
    init = function(plugin)
      -- The repository keeps its Neovim colors under a nested vim/ directory.
      vim.opt.rtp:append(plugin.dir .. "/vim")
    end,
    config = function()
      vim.cmd.colorscheme("onehalfdark")
      vim.api.nvim_set_hl(0, "Comment", { fg = "#6A9955", italic = true })
      vim.api.nvim_set_hl(0, "@comment", { link = "Comment" })
      vim.api.nvim_set_hl(0, "Keyword", { fg = "#C678DD" })
      vim.api.nvim_set_hl(0, "Identifier", { fg = "#61AFEF" })
      vim.api.nvim_set_hl(0, "@keyword", { link = "Keyword" })
      vim.api.nvim_set_hl(0, "@keyword.function", { link = "Keyword" })
      vim.api.nvim_set_hl(0, "@keyword.modifier", { link = "Keyword" })
      -- Match LSP hover/signature popups with the OneHalfDark palette.
      vim.api.nvim_set_hl(0, "NormalFloat", { fg = "#DCDFE4", bg = "#282C34" })
      vim.api.nvim_set_hl(0, "FloatBorder", { fg = "#5C6370", bg = "#282C34" })
      vim.api.nvim_set_hl(0, "FloatTitle", { fg = "#61AFEF", bg = "#282C34", bold = true })
      vim.api.nvim_set_hl(0, "WinSeparator", { fg = "#475569" })
      vim.api.nvim_set_hl(0, "VertSplit", { link = "WinSeparator" })
      vim.api.nvim_set_hl(0, "GitSignsAdd", { fg = "#98C379" })
      vim.api.nvim_set_hl(0, "GitSignsChange", { fg = "#E5C07B" })
      vim.api.nvim_set_hl(0, "GitSignsDelete", { fg = "#E06C75" })
      -- Muted off-white: readable, but quieter than Normal (#DCDFE4).
      vim.api.nvim_set_hl(0, "LspInlayHint", { fg = "#9299A5", bg = "#282C34", italic = true })

      -- Let the terminal wallpaper show through without changing foreground colors.
      for _, group in ipairs({
        "Normal",
        "NormalNC",
        "EndOfBuffer",
        "SignColumn",
        "FoldColumn",
        "LineNr",
        "CursorLineNr",
        "NormalFloat",
        "FloatBorder",
        "FloatTitle",
        "LspInlayHint",
      }) do
        local highlight = vim.api.nvim_get_hl(0, { name = group, link = false })
        highlight.bg = nil
        highlight.ctermbg = nil
        vim.api.nvim_set_hl(0, group, highlight)
      end
    end,
  },
  {
    "nvim-telescope/telescope.nvim",
    version = false,
    cmd = "Telescope",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      {
        "<leader>ff",
        function()
          require("telescope.builtin").find_files({ hidden = true })
        end,
        desc = "Find files",
      },
    },
    opts = {
      defaults = {
        mappings = {
          i = {
            ["<Esc>"] = function(prompt_bufnr)
              require("telescope.actions").close(prompt_bufnr)
            end,
            ["<leader>cp"] = function()
              copy_telescope_file_path()
            end,
          },
          n = {
            ["<leader>cp"] = function()
              copy_telescope_file_path()
            end,
          },
        },
      },
      pickers = {
        find_files = { hidden = true },
      },
    },
  },
  {
    "nvim-tree/nvim-tree.lua",
    lazy = false,
    dependencies = { "nvim-tree/nvim-web-devicons" },
    init = function()
      vim.api.nvim_create_autocmd("VimEnter", {
        once = true,
        callback = function()
          require("nvim-tree.api").tree.open({ path = nvim_startup_cwd })
        end,
      })
    end,
    keys = {
      {
        "<C-b>",
        "<cmd>NvimTreeToggle<CR>",
        desc = "Toggle sidebar",
      },
    },
    opts = {
      sync_root_with_cwd = false,
      view = {
        preserve_window_proportions = true,
      },
      on_attach = function(bufnr)
        local api = require("nvim-tree.api")

        api.map.on_attach.default(bufnr)

        local function locked_key_opts(desc)
          return {
            buffer = bufnr,
            desc = "nvim-tree: " .. desc,
            noremap = true,
            nowait = true,
            silent = true,
          }
        end

        -- Keep the tree rooted at the directory Neovim was launched from.
        vim.keymap.set("n", "<BS>", "<Nop>", locked_key_opts("Backspace disabled"))
        vim.keymap.set("n", "-", "<Nop>", locked_key_opts("Parent directory disabled"))
        vim.keymap.set("n", "<C-]>", "<Nop>", locked_key_opts("Change root disabled"))
        vim.keymap.set("n", "<2-RightMouse>", "<Nop>", locked_key_opts("Change root disabled"))
      end,
      update_focused_file = {
        enable = true,
        update_root = false,
      },
      actions = {
        change_dir = {
          enable = false,
          restrict_above_cwd = true,
        },
      },
      view = {
        width = 32,
      },
      renderer = {
        group_empty = true,
      },
      filters = {
        dotfiles = false,
      },
    },
  },
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      signs = {
        add = { text = "▎" },
        change = { text = "▎" },
        delete = { text = "▁" },
        topdelete = { text = "▔" },
        changedelete = { text = "▎" },
        untracked = { text = "┆" },
      },
      current_line_blame = false,
      on_attach = function(bufnr)
        local function git_map(lhs, rhs, desc)
          map("n", lhs, rhs, { buffer = bufnr, desc = desc })
        end

        git_map("]h", "<cmd>Gitsigns nav_hunk next<CR>", "Next Git change")
        git_map("[h", "<cmd>Gitsigns nav_hunk prev<CR>", "Previous Git change")
      end,
    },
  },
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = function()
      local colors = {
        blue = "#61AFEF",
        green = "#98C379",
        yellow = "#E5C07B",
        red = "#E06C75",
        purple = "#C678DD",
        fg = "#DCDFE4",
        muted = "#7F848E",
        transparent = "none",
      }

      local function mode_style(color)
        return { fg = color, bg = colors.transparent, gui = "bold" }
      end

      local function current_mode_style()
        local mode = vim.fn.mode(1)
        local color = colors.blue

        if mode:match("^i") or mode == "t" then
          color = colors.green
        elseif mode == "v" or mode == "V" or mode == "\22" or mode == "s" or mode == "S" or mode == "\19" then
          color = colors.purple
        elseif mode:match("^R") then
          color = colors.red
        elseif mode:match("^[cr!]") then
          color = colors.yellow
        end

        return mode_style(color)
      end

      local minimal_theme = {
        normal = {
          a = mode_style(colors.blue),
          b = { fg = colors.fg, bg = colors.transparent },
          c = { fg = colors.muted, bg = colors.transparent },
        },
        insert = {
          a = mode_style(colors.green),
          b = { fg = colors.fg, bg = colors.transparent },
          c = { fg = colors.muted, bg = colors.transparent },
        },
        visual = {
          a = mode_style(colors.purple),
          b = { fg = colors.fg, bg = colors.transparent },
          c = { fg = colors.muted, bg = colors.transparent },
        },
        replace = {
          a = mode_style(colors.red),
          b = { fg = colors.fg, bg = colors.transparent },
          c = { fg = colors.muted, bg = colors.transparent },
        },
        command = {
          a = mode_style(colors.yellow),
          b = { fg = colors.fg, bg = colors.transparent },
          c = { fg = colors.muted, bg = colors.transparent },
        },
        inactive = {
          a = { fg = colors.muted, bg = colors.transparent },
          b = { fg = colors.muted, bg = colors.transparent },
          c = { fg = colors.muted, bg = colors.transparent },
        },
      }

      return {
        options = {
          theme = minimal_theme,
          globalstatus = true,
          icons_enabled = false,
          component_separators = "",
          section_separators = "",
        },
        sections = {
          lualine_a = {},
          lualine_b = {
            {
              function()
                return vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
              end,
              padding = { left = 1, right = 1 },
            },
            {
              "branch",
              fmt = function(branch)
                return branch == "" and "" or "git(" .. branch .. ")"
              end,
              color = { fg = colors.yellow, bg = colors.transparent },
              padding = { left = 0, right = 1 },
            },
          },
          lualine_c = {
            {
              "filename",
              path = 0,
              symbols = { modified = " *", readonly = " [RO]", unnamed = "[No Name]", newfile = "[New]" },
            },
            {
              "mode",
              color = current_mode_style,
              padding = { left = 1, right = 1 },
            },
          },
          lualine_x = { "diagnostics" },
          lualine_y = { "filetype", "location" },
          lualine_z = {},
        },
      }
    end,
  },
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    opts = {
      check_ts = false,
      enable_check_bracket_line = true,
    },
  },
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "master",
    build = ":TSUpdate",
    lazy = false,
    opts = {
      highlight = {
        enable = true,
      },
      indent = {
        enable = true,
      },
    },
    config = function(_, opts)
      require("nvim-treesitter.configs").setup(opts)
    end,
  },
}, {
  checker = { enabled = true, notify = false },
  change_detection = { notify = false },
})
