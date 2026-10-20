-- Run with nvim --headless -u NONE -i NONE -l scripts/nvim.lua setup|parsers|verify
local mode = arg[1]
vim.opt.loadplugins = true
local config_path = vim.fn.stdpath("config") .. "/init.lua"
local lock_path = vim.fn.stdpath("config") .. "/lazy-lock.json"
local errors = {}
local notify = vim.notify
vim.notify = function(message, level, opts)
  if level == vim.log.levels.ERROR then
    errors[#errors + 1] = tostring(message)
  end
  notify(message, level, opts)
end

local function command(args)
  local result = vim.fn.system(args)
  assert(vim.v.shell_error == 0, table.concat(args, " ") .. "\n" .. result)
  return vim.trim(result)
end

local function check_commits(lock)
  local config = require("lazy.core.config")
  for name, entry in pairs(lock) do
    local plugin = assert(config.plugins[name], "Unknown locked plugin: " .. name)
    local actual = command({ "git", "-C", plugin.dir, "rev-parse", "HEAD" })
    assert(actual == entry.commit, name .. " differs from lockfile; run zdotfiles setup --only nvim")
  end
  for name, plugin in pairs(config.plugins) do
    assert(lock[name], "Plugin is not locked: " .. name)
    assert(not require("lazy.core.plugin").has_errors(plugin), "Plugin operation failed: " .. name)
  end
end

local function main()
  assert(mode == "setup" or mode == "parsers" or mode == "verify", "Invalid mode")
  local lock = vim.json.decode(table.concat(vim.fn.readfile(lock_path), "\n"))
  if mode == "setup" then
    vim.g.zdotfiles_collect_plugins = true
    local specs = dofile(config_path)
    local lazy_path = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
    if not vim.uv.fs_stat(lazy_path) then
      command({ "git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", lazy_path })
    end
    assert(command({ "git", "-C", lazy_path, "status", "--porcelain" }) == "", "lazy.nvim has local changes")
    if command({ "git", "-C", lazy_path, "rev-parse", "HEAD" }) ~= lock["lazy.nvim"].commit then
      command({ "git", "-C", lazy_path, "fetch", "origin", lock["lazy.nvim"].commit })
      command({ "git", "-C", lazy_path, "checkout", "--detach", lock["lazy.nvim"].commit })
    end
    vim.opt.rtp:prepend(lazy_path)
    -- Disable execution while restoring; the next process loads the real config.
    for _, spec in ipairs(specs) do
      spec.init, spec.config, spec.opts, spec.build = nil, false, nil, false
      spec.lazy = true
      spec.event, spec.cmd, spec.ft, spec.keys = nil, nil, nil, nil
    end
    require("lazy").setup(specs, {
      install = { missing = false },
      checker = { enabled = false },
      change_detection = { enabled = false },
    })
    -- Restore must never replace the authoritative lock with installed versions.
    require("lazy.manage.lock").update = function() end
    require("lazy").install({ wait = true, show = false, lockfile = true })
    require("lazy").restore({ wait = true, show = false })
    check_commits(lock)
  else
    vim.g.zdotfiles_verify = true
    dofile(config_path)
    check_commits(lock)
    require("lazy").load({ plugins = vim.tbl_keys(require("lazy.core.config").plugins) })
    vim.api.nvim_exec_autocmds("VimEnter", { modeline = false })
    vim.api.nvim_exec_autocmds("BufEnter", { modeline = false })
    if mode == "parsers" then
      vim.cmd("TSUpdateSync " .. table.concat(vim.g.zdotfiles_parsers, " "))
    end
    for _, language in ipairs(vim.g.zdotfiles_parsers) do
      local parser_path = require("lazy.core.config").plugins["nvim-treesitter"].dir
        .. "/parser/" .. language .. ".so"
      assert(vim.uv.fs_stat(parser_path), "Missing managed parser: " .. language)
      vim.treesitter.language.add(language, { path = parser_path })
      local buffer = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_set_current_buf(buffer)
      local parser = vim.treesitter.get_parser(buffer, language)
      assert(parser, "Missing parser: " .. language)
      parser:parse()
      vim.treesitter.start(buffer, language)
      vim.api.nvim_buf_delete(buffer, { force = true })
    end
  end
  vim.wait(100)
  assert(#errors == 0, table.concat(errors, "\n"))
  print("ok         Neovim " .. mode)
end

local ok, message = xpcall(main, debug.traceback)
if not ok then
  io.stderr:write(tostring(message) .. "\n")
  vim.cmd("cquit 1")
end
vim.cmd("qa!")
