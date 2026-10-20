"""Exercise dependency provisioning with fake package managers; never call sudo or the network."""
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
    log = root / "install.log"
    for name in ("bash", "dirname", "mkdir", "chmod", "ln", "cp", "mv", "cmp", "date", "git", "cc", "curl", "tar"):
        (commands / name).symlink_to(shutil.which(name))
    fake = root / "fake.py"
    fake.write_text('''#!/usr/bin/python3
import os, sys
from pathlib import Path
name = Path(sys.argv[0]).name
args = sys.argv[1:]
commands = Path(os.environ["FAKE_COMMANDS"])
state = commands.parent

def tool(name):
    (commands / name).symlink_to(state / "fake.py")

if name == "nvim":
    if "--version" in args: print("NVIM v0.11.6")
    sys.exit(0)
if name == "sudo":
    os.execv(commands / args[0], args)
if name == "apt-get":
    with open(os.environ["FAKE_LOG"], "a") as f: f.write("apt " + " ".join(args) + "\\n")
    if os.environ.get("FAIL_APT"): sys.exit(1)
    if args[0] == "install":
        for package in args[2:]:
            names = {"ripgrep": ["rg"], "rustup": ["rustup"], "python3-venv": ["python3"],
                     "wl-clipboard": ["wl-copy", "wl-paste"], "xclip": ["xclip"]}[package]
            for command in names: tool(command)
    sys.exit(0)
if name == "rustup":
    if args[0] == "toolchain":
        with open(os.environ["FAKE_LOG"], "a") as f: f.write("rust " + " ".join(args) + "\\n")
    sys.exit(0)
if name == "python3" or name == "python":
    if args[0] == "-c": sys.exit(0)
    if args[1] == "venv":
        directory = Path(args[2]) / "bin"
        directory.mkdir(parents=True)
        (directory / "python").symlink_to(state / "fake.py")
    elif args[1] == "pip":
        with open(os.environ["FAKE_LOG"], "a") as f: f.write("pip " + " ".join(args) + "\\n")
        (Path(sys.argv[0]).parent / "basedpyright-langserver").symlink_to(state / "fake.py")
    sys.exit(0)
''')
    fake.chmod(0o755)
    for name in ("nvim", "apt-get", "sudo"):
        (commands / name).symlink_to(fake)
    environment = dict(os.environ, HOME=str(home), PATH=str(commands),
                       XDG_CONFIG_HOME=str(home / ".config"), XDG_DATA_HOME=str(home / ".local/share"),
                       XDG_STATE_HOME=str(home / ".local/state"), FAKE_COMMANDS=str(commands), FAKE_LOG=str(log))
    for key in ("DISPLAY", "WAYLAND_DISPLAY", "NVIM_APPNAME"):
        environment.pop(key, None)

    def run(action, *options, success=True, extra=None):
        result = subprocess.run([str(repository / "zdotfiles"), action, "--only", "nvim", *options],
                                env=environment | (extra or {}), capture_output=True, text=True)
        assert (result.returncode == 0) == success, result.stdout + result.stderr
        return result.stdout + result.stderr

    # The suite targets the same Ubuntu platform as automatic provisioning.
    os_release = Path('/etc/os-release').read_text()
    assert 'ID=ubuntu' in os_release and 'VERSION_ID="26.04"' in os_release
    output = run("setup", "--dry-run")
    assert 'ripgrep rustup python3-venv' in output
    assert not log.exists() and not home.exists()
    run("verify", success=False)
    assert not log.exists() and not home.exists(), "verify must never provision"
    run("setup", success=False, extra={"FAIL_APT": "1"})
    assert not home.exists(), "apt failure must stop before deploying config"
    log.unlink()
    run("setup")
    installs = log.read_text()
    assert 'apt install -y ripgrep rustup python3-venv' in installs
    assert 'toolchain install stable' in installs and 'basedpyright==1.40.2' in installs
    run("verify")
    run("setup")
    assert log.read_text() == installs, "repeat setup must skip existing dependencies"
    run("setup", extra={"WAYLAND_DISPLAY": "wayland-0"})
    assert 'apt install -y wl-clipboard' in log.read_text()
    run("setup", extra={"DISPLAY": ":0"})
    assert 'apt install -y xclip' in log.read_text()
    alternate = root / 'alternate'
    installs = log.read_text()
    run("setup", "--home", str(alternate))
    assert log.read_text() == installs
    assert (alternate / '.config/nvim/init.lua').exists()
print('Dependency dry-run, verify, install failure, install, repeat setup, clipboard, and alternate-home checks passed')
