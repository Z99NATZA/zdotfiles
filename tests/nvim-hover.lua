-- Requires the installed, locked nvim-treesitter and managed Rust/Python parsers.
-- Run with nvim --headless -u NONE -i NONE -l tests/nvim-hover.lua
local ok, message = xpcall(function()
  local executable = vim.fn.executable
  vim.fn.executable = function(name)
    if name == "rust-analyzer" or name == "basedpyright-langserver" then
      return 0
    end
    return executable(name)
  end
  vim.g.zdotfiles_collect_plugins = true
  local specs = dofile(".config/nvim/init.lua")
  local plugin = vim.fn.stdpath("data") .. "/lazy/nvim-treesitter"
  assert(vim.fn.isdirectory(plugin) == 1, "Run make setup-nvim first")
  vim.opt.rtp:prepend(plugin)
  dofile(plugin .. "/plugin/nvim-treesitter.lua")
  for _, spec in ipairs(specs) do
    if spec[1] == "nvim-treesitter/nvim-treesitter" then
      spec.config(nil, spec.opts)
    end
  end
  vim.cmd("syntax on")

  for _, example in ipairs({
    { language = "rust", code = "let minz: f32" },
    { language = "python", code = "minz: float", focus = true },
  }) do
    vim.v.errmsg = ""
    local source_window = vim.api.nvim_get_current_win()
    local source_cursor = vim.api.nvim_win_get_cursor(source_window)
    local buffer, window = vim.lsp.util.open_floating_preview({
      "```" .. example.language,
      example.code,
      "```",
      "",
      "Variable **documentation**.",
    }, "markdown", { border = "rounded" })
    local parser = vim.treesitter.get_parser(buffer, "markdown")
    parser:parse(true)
    local languages = {}
    parser:for_each_tree(function(_, tree)
      languages[tree:lang()] = true
    end)
    assert(languages[example.language], "Hover must highlight " .. example.language .. " code")
    assert(languages.markdown_inline, "Hover must highlight inline Markdown")
    assert(vim.treesitter.highlighter.active[buffer], "Hover highlighting must remain enabled")
    vim.cmd("redraw")
    assert(vim.v.errmsg == "", vim.v.errmsg)
    if example.focus then
      vim.api.nvim_set_current_win(window)
    end
    vim.api.nvim_feedkeys(vim.keycode("<Esc>"), "xt", false)
    assert(not vim.api.nvim_win_is_valid(window), "Esc must close the hover")
    assert(vim.api.nvim_get_current_win() == source_window, "Esc must keep focus in the source window")
    assert(vim.deep_equal(vim.api.nvim_win_get_cursor(source_window), source_cursor), "Esc must keep the cursor still")
  end

  local buffer = vim.api.nvim_create_buf(false, true)
  local window = vim.api.nvim_open_win(buffer, false, {
    relative = "editor", row = 0, col = 0, width = 10, height = 1,
  })
  vim.api.nvim_feedkeys(vim.keycode("<Esc>"), "xt", false)
  assert(vim.api.nvim_win_is_valid(window), "Esc must leave unrelated floating windows open")
  vim.api.nvim_win_close(window, true)
  print("Rust/Python hover rendering, syntax highlighting, and Esc dismissal checks passed")
end, debug.traceback)
if not ok then
  io.stderr:write(message .. "\n")
  vim.cmd("cquit 1")
end
vim.cmd("qa!")
