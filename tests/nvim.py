"""Real Neovim integration checks in an isolated home; requires network and dependencies."""
import os
from pathlib import Path
import subprocess
import tempfile

repository = Path(__file__).resolve().parents[1]
with tempfile.TemporaryDirectory(prefix="zdotfiles-nvim-test-") as temporary:
    home = Path(temporary) / "home"
    environment = dict(os.environ, HOME=str(home), XDG_CONFIG_HOME=str(home / ".config"),
                       XDG_DATA_HOME=str(home / ".local/share"),
                       XDG_STATE_HOME=str(home / ".local/state"),
                       XDG_CACHE_HOME=str(home / ".cache"),
                       RUSTUP_HOME=os.environ.get("RUSTUP_HOME", str(Path.home() / ".rustup")),
                       CARGO_HOME=os.environ.get("CARGO_HOME", str(Path.home() / ".cargo")))
    environment.pop("NVIM_APPNAME", None)

    def run(action, *options, success=True):
        result = subprocess.run([str(repository / "zdotfiles"), action, "--only", "nvim", *options],
                                env=environment, text=True, capture_output=True, timeout=600)
        assert (result.returncode == 0) == success, result.stdout + result.stderr
        return result.stdout + result.stderr

    run("setup", "--dry-run")
    assert not home.exists(), "dry-run must leave a fresh home untouched"
    run("verify", success=False)
    run("setup")
    lock = home / ".config/nvim/lazy-lock.json"
    expected = (repository / ".config/nvim/lazy-lock.json").read_bytes()
    assert lock.read_bytes() == expected, "setup must preserve the authoritative lock"
    run("verify")
    run("setup")
    assert lock.read_bytes() == expected

    plugin = home / ".local/share/nvim/lazy/nvim-treesitter"
    subprocess.run(["git", "-C", str(plugin), "checkout", "--detach", "HEAD~1"], check=True)
    assert "differs from lockfile" in run("verify", success=False)
    run("setup")
    run("verify")

    parser = plugin / "parser/python.so"
    hidden = parser.with_suffix(".hidden")
    parser.rename(hidden)
    try:
        run("verify", success=False)
        assert not parser.exists(), "verify must not install missing parsers"
    finally:
        hidden.rename(parser)

    config = home / ".config/nvim/init.lua"
    original = config.read_text()
    config.write_text(original + '\nvim.notify("simulated config failure", vim.log.levels.ERROR)\n')
    assert "simulated config failure" in run("verify", success=False)
    config.write_text(original)
    run("verify")
print("Neovim clean install, repeated setup, drift repair, missing parser, and startup error checks passed")
