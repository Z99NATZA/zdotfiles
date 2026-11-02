"""Check Make hint preferences and Neovim refreshes without plugins or LSPs."""
import os
from pathlib import Path
import subprocess
import tempfile

repository = Path(__file__).resolve().parents[1]
with tempfile.TemporaryDirectory(prefix="zdotfiles-hints-") as temporary:
    root = Path(temporary)
    environment = dict(os.environ, XDG_CONFIG_HOME=str(root / "config"),
                       XDG_DATA_HOME=str(root / "data"), XDG_STATE_HOME=str(root / "state"),
                       XDG_CACHE_HOME=str(root / "cache"), NVIM_APPNAME="hints-test")
    probe = root / "probe.lua"
    probe.write_text('''
local executable = vim.fn.executable
vim.fn.executable = function(name)
  if name == "rust-analyzer" or name == "basedpyright-langserver" then return 0 end
  return executable(name)
end
vim.g.zdotfiles_collect_plugins = true
dofile(arg[1])
local buffers = {}
for index, filetype in ipairs({ "rust", "python" }) do
  local buffer = vim.api.nvim_create_buf(false, true)
  vim.bo[buffer].filetype = filetype
  buffers[buffer] = arg[index + 1] == "true"
end
vim.lsp.get_client_by_id = function()
  return { supports_method = function() return true end, attached_buffers = buffers }
end
local function check()
  for buffer, expected in pairs(buffers) do
    assert(vim.lsp.inlay_hint.is_enabled({ bufnr = buffer }) == expected,
      "Incorrect hint preference for " .. vim.bo[buffer].filetype)
  end
end
check()
for buffer in pairs(buffers) do
  vim.api.nvim_exec_autocmds("LspAttach", { buffer = buffer, data = { client_id = 1 } })
end
vim.api.nvim_exec_autocmds("LspProgress", { pattern = "end", data = { client_id = 1 } })
check()
vim.wait(3100)
check()
''')

    def run(*command):
        result = subprocess.run(command, cwd=repository, env=environment,
                                capture_output=True, text=True, timeout=30)
        assert result.returncode == 0, result.stdout + result.stderr

    config = root / "config/hints-test/init.lua"

    def check(rust, python, path=config):
        run("nvim", "--headless", "-u", "NONE", "-i", "NONE", "-l", str(probe),
            str(path), str(rust).lower(), str(python).lower())

    check(True, True, repository / ".config/nvim/init.lua")
    config.parent.mkdir(parents=True, exist_ok=True)
    stale = b'-- Old config that always enables hints\nvim.lsp.inlay_hint.enable(true)\n'
    config.write_bytes(stale)
    run("make", "disable-hint-rust")
    assert config.read_bytes() == (repository / ".config/nvim/init.lua").read_bytes()
    backups = list((root / "state/hints-test/zdotfiles/backups").glob("*/init.lua"))
    assert len(backups) == 1 and backups[0].read_bytes() == stale
    check(False, True)
    run("make", "disable-hint-py")
    run("make", "disable-hint-py")  # Repeated commands must be safe.
    check(False, False)
    run("make", "enable-hint-rust")
    check(True, False)
    run("make", "enable-hint-py")
    run("make", "enable-hint-py")
    check(True, True)
    assert len(list((root / "state/hints-test/zdotfiles/backups").glob("*/init.lua"))) == 1
    config.unlink()
    run("make", "disable-hint-rust")
    check(False, True)
print("Config install/upgrade, backups, hint preferences, and LSP refresh checks passed")
