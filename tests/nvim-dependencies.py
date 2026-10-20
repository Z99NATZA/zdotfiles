"""Check required/optional dependencies without package managers or network access."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

repository = Path(__file__).resolve().parents[1]
with tempfile.TemporaryDirectory(prefix="zdotfiles-deps-") as temporary:
    root = Path(temporary)
    commands = root / "commands"
    commands.mkdir()
    home = root / "home"
    log = root / "forbidden.log"
    for name in ("bash", "dirname", "mkdir", "cp", "mv", "cmp", "date", "git", "cc", "curl", "tar"):
        (commands / name).symlink_to(shutil.which(name))
    fake_nvim = commands / "nvim"
    fake_nvim.write_text('#!/bin/bash\nif [[ $1 = --version ]]; then echo "NVIM v${FAKE_NVIM_VERSION:-0.11.6}"; fi\n')
    fake_nvim.chmod(0o755)
    # Any attempt to install system packages or language servers fails the test.
    for name in ("sudo", "apt", "apt-get", "pip", "pipx", "rustup", "python3"):
        path = commands / name
        path.write_text('#!/bin/bash\nprintf "%s\\n" "$0 $*" >> "$FORBIDDEN_LOG"\nexit 99\n')
        path.chmod(0o755)
    environment = dict(os.environ, HOME=str(home), PATH=str(commands),
                       XDG_CONFIG_HOME=str(home / ".config"), XDG_DATA_HOME=str(home / ".local/share"),
                       XDG_STATE_HOME=str(home / ".local/state"), FORBIDDEN_LOG=str(log))
    for key in ("DISPLAY", "WAYLAND_DISPLAY", "NVIM_APPNAME"):
        environment.pop(key, None)

    def run(action, *options, success=True, extra=None):
        result = subprocess.run([str(repository / "zdotfiles"), action, "--only", "nvim", *options],
                                env=environment | (extra or {}), capture_output=True, text=True)
        assert (result.returncode == 0) == success, result.stdout + result.stderr
        assert not log.exists(), "setup/verify must never invoke package installers"
        return result.stdout + result.stderr

    output = run("setup", "--dry-run")
    assert 'optional   rg' in output and 'Rust LSP disabled' in output and 'Python LSP disabled' in output
    assert not home.exists()
    run("verify", success=False)
    assert not home.exists()
    (commands / 'cc').unlink()
    assert 'missing    Neovim dependency: cc' in run('setup', success=False)
    assert not home.exists(), 'required dependency failure must precede config deployment'
    run('setup', '--dry-run', success=False)
    (commands / 'cc').symlink_to(shutil.which('cc'))
    run('setup', success=False, extra={'FAKE_NVIM_VERSION': '0.10.4'})
    assert not home.exists()
    run("setup")
    run("verify")
    run("setup")
    assert 'optional   Wayland clipboard' in run("setup", extra={"WAYLAND_DISPLAY": "wayland-0"})
    assert 'optional   X11 clipboard' in run("verify", extra={"DISPLAY": ":0"})
    # A rustup proxy can exist without an installed toolchain; this remains optional.
    proxy = commands / 'rust-analyzer'
    proxy.write_text('#!/bin/bash\nexit 1\n')
    proxy.chmod(0o755)
    assert 'Rust LSP disabled' in run('setup')
    (commands / 'cc').unlink()
    alternate = root / 'alternate'
    run("setup", "--home", str(alternate))
    assert (alternate / '.config/nvim/init.lua').exists()
print('Required/optional dependency checks passed; no package installers invoked')
