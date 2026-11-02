-- Update the installed config and preference without loading plugins or LSPs.
local action, language = arg[1], arg[2]
assert(action == "enable" or action == "disable", "Expected enable or disable")
assert(language == "rust" or language == "py", "Expected rust or py")

local repository = vim.fn.fnamemodify(arg[0], ":p:h:h")
local source = vim.fn.readfile(repository .. "/.config/nvim/init.lua", "b")
local config_directory = vim.fn.stdpath("config")
local config_path = config_directory .. "/init.lua"
local installed = vim.fn.filereadable(config_path) == 1 and vim.fn.readfile(config_path, "b") or nil
if not vim.deep_equal(source, installed) then
  if installed then
    local backup_directory = vim.fn.stdpath("state") .. "/zdotfiles/backups/"
      .. os.date("%Y%m%d-%H%M%S") .. "-hints-" .. vim.uv.os_getpid()
    vim.fn.mkdir(backup_directory, "p")
    assert(vim.fn.writefile(installed, backup_directory .. "/init.lua", "b") == 0, "Cannot back up config")
    print("Config backup: " .. backup_directory .. "/init.lua")
  end
  vim.fn.mkdir(config_directory, "p")
  local staged = config_path .. ".zdotfiles-stage." .. vim.uv.os_getpid()
  assert(vim.fn.writefile(source, staged, "b") == 0, "Cannot stage config: " .. staged)
  local ok, message = vim.uv.fs_rename(staged, config_path)
  if not ok then
    vim.fn.delete(staged)
    error(message)
  end
end

local directory = vim.fn.stdpath("state") .. "/zdotfiles/hints"
local path = directory .. "/" .. language .. ".disabled"
if action == "disable" then
  vim.fn.mkdir(directory, "p")
  assert(vim.fn.writefile({}, path) == 0, "Cannot save hint preference: " .. path)
elseif vim.fn.filereadable(path) == 1 then
  assert(vim.fn.delete(path) == 0, "Cannot remove hint preference: " .. path)
end
print(language .. " inlay hints: " .. (action == "enable" and "enabled" or "disabled") .. "; reopen Neovim to apply")
