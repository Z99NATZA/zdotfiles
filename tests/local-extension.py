"""Integration checks using the real VS Code CLI in temporary directories."""
import importlib.util
import json
import os
import shutil
import sys
from pathlib import Path
import subprocess
import tempfile

spec = importlib.util.spec_from_file_location('local_extension', Path(__file__).resolve().parents[1] / 'scripts/local-extension.py')
helper = importlib.util.module_from_spec(spec)
spec.loader.exec_module(helper)

with tempfile.TemporaryDirectory(prefix='zdotfiles-test-') as temporary:
    root = Path(temporary)
    extensions = root / 'extensions'
    vsix = root / 'resizer.vsix'
    helper.package_vsix(helper.SOURCE, vsix)
    assert not helper.installed(helper.SOURCE, extensions)
    command = ['code', '--user-data-dir', str(root / 'user-data'), '--extensions-dir', str(extensions), '--install-extension', str(vsix), '--force']
    subprocess.run(command, check=True)
    assert helper.installed(helper.SOURCE, extensions), 'VSIX must register and match source'
    registry = json.loads((extensions / 'extensions.json').read_text())
    location = Path(registry[0]['location']['path'])
    (location / 'extension.js').write_text('// stale payload\n')
    assert not helper.installed(helper.SOURCE, extensions), 'changed payload must require reinstall'
    subprocess.run(command, check=True)
    assert helper.installed(helper.SOURCE, extensions), 'same-version reinstall must repair payload'
    (extensions / '.obsolete').write_text(json.dumps({location.name: True}))
    assert not helper.installed(helper.SOURCE, extensions), 'obsolete extension must fail verify'
    subprocess.run(command, check=True)
    assert helper.installed(helper.SOURCE, extensions), 'CLI must repair obsolete installation'
    (extensions / 'extensions.json').write_text('[]')
    assert not helper.installed(helper.SOURCE, extensions), 'copied files alone must fail verify'
    subprocess.run(command, check=True)
    assert helper.installed(helper.SOURCE, extensions), 'CLI must repair missing registration'
print('Local extension integration checks passed')

# Exercise the public setup/verify entry points with a real isolated VS Code CLI.

repository = Path(__file__).resolve().parents[1]
real_code = shutil.which('code')
assert real_code, 'VS Code CLI is required'
with tempfile.TemporaryDirectory(prefix='zdotfiles-setup-test-') as temporary:
    root = Path(temporary)
    home = root / 'home'
    commands = root / 'commands'
    commands.mkdir()
    log = root / 'code.log'
    marketplace = '\n'.join(
        line for line in (repository / 'manifest/vscode-extensions.txt').read_text().splitlines()
        if line and not line.startswith('#')
    )
    wrapper = commands / 'code'
    wrapper.write_text(
        f'#!{sys.executable}\n'
        'import os, sys\n'
        f'with open({str(log)!r}, "a") as log: log.write(repr(sys.argv[1:]) + "\\n")\n'
        'if sys.argv[1:] == ["--list-extensions"]:\n'
        f'    print({marketplace!r})\n'
        'else:\n'
        f'    os.execv({real_code!r}, [{real_code!r}, "--user-data-dir", '
        f'{str(root / "user-data")!r}] + sys.argv[1:])\n'
    )
    wrapper.chmod(0o755)
    environment = dict(os.environ, HOME=str(home), PATH=str(commands) + os.pathsep + os.environ['PATH'],
                       XDG_CONFIG_HOME=str(home / '.config'), XDG_DATA_HOME=str(home / '.local/share'),
                       XDG_STATE_HOME=str(home / '.local/state'), PYTHONDONTWRITEBYTECODE='1')

    def run(action, *options, success=True):
        result = subprocess.run(
            ['bash', str(repository / 'zdotfiles'), action, '--skip-system-settings', *options],
            env=environment, capture_output=True, text=True,
        )
        assert (result.returncode == 0) == success, result.stdout + result.stderr
        return result.stdout

    output = run('setup', '--only', 'vscode', '--dry-run')
    assert 'would package and install' in output
    assert not home.exists(), 'dry run must not create configuration or extension files'
    output = run('setup', '--only', 'vscode')
    assert 'installed  VS Code extension znnn.focused-pane-resizer' in output
    run('verify', '--only', 'vscode')
    previous_log = log.read_text()
    output = run('setup', '--only', 'vscode')
    assert 'unchanged  VS Code extension znnn.focused-pane-resizer' in output
    assert log.read_text().count('--install-extension') == previous_log.count('--install-extension')
    registry = json.loads((home / '.vscode/extensions/extensions.json').read_text())
    payload = Path(registry[0]['location']['path']) / 'extension.js'
    payload.write_text('// stale payload\n')
    run('verify', '--only', 'vscode', success=False)
    run('setup', '--only', 'vscode')
    run('verify', '--only', 'vscode')

    previous_log = log.read_text()
    run('setup', '--only', 'vscode', '--skip-extensions')
    run('verify', '--only', 'vscode', '--skip-extensions')
    nvim_home = root / 'nvim-home'
    run('setup', '--only', 'nvim', '--home', str(nvim_home))
    run('verify', '--only', 'nvim', '--home', str(nvim_home))
    alternate_home = root / 'alternate-home'
    run('setup', '--only', 'vscode', '--home', str(alternate_home))
    run('verify', '--only', 'vscode', '--home', str(alternate_home))
    assert not (alternate_home / '.vscode').exists()
    assert log.read_text() == previous_log, 'skip, nvim, and alternate-home paths must not call code'
print('Setup and verify integration checks passed')
