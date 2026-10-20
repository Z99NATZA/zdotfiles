-- Run with nvim --headless -u NONE -i NONE -l tests/nvim-optional.lua
local ok, message = xpcall(function()
  local executable, system = vim.fn.executable, vim.system
  local broken_proxy = false
  vim.fn.executable = function(name)
    if name == "rust-analyzer" then
      return broken_proxy and 1 or 0
    elseif name == "basedpyright-langserver" then
      return 0
    end
    return executable(name)
  end
  vim.system = function(command, ...)
    if command[1] == "rust-analyzer" then
      return { wait = function() return { code = 1 } end }
    end
    return system(command, ...)
  end
  vim.g.zdotfiles_collect_plugins = true
  for _, proxy in ipairs({ false, true }) do
    broken_proxy = proxy
    dofile(".config/nvim/init.lua")
    assert(not vim.lsp.is_enabled("rust_analyzer"), "Unavailable Rust LSP must stay disabled")
    assert(not vim.lsp.is_enabled("basedpyright"), "Unavailable Python LSP must stay disabled")
  end
  print("Missing language servers and broken rustup proxy checks passed")
end, debug.traceback)
if not ok then
  io.stderr:write(message .. "\n")
  vim.cmd("cquit 1")
end
vim.cmd("qa!")
