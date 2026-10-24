"""Exercise the public GNOME installer on an isolated dconf session and home."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

REPO = Path(__file__).resolve().parents[1]

if os.environ.get('ZDOTFILES_GNOME_TEST_SESSION') != '1':
    with tempfile.TemporaryDirectory(prefix='zdotfiles-gnome-') as directory:
        root = Path(directory)
        environment = dict(os.environ, ZDOTFILES_GNOME_TEST_SESSION='1',
                           ZDOTFILES_GNOME_TEST_ROOT=directory,
                           HOME=str(root / 'home'), XDG_CONFIG_HOME=str(root / 'config'),
                           XDG_DATA_HOME=str(root / 'data'), XDG_STATE_HOME=str(root / 'state'),
                           XDG_CACHE_HOME=str(root / 'cache'), FONTCONFIG_FILE='/etc/fonts/fonts.conf',
                           GSETTINGS_BACKEND='dconf', PYTHONDONTWRITEBYTECODE='1')
        environment.pop('GSETTINGS_SCHEMA_DIR', None)
        environment.pop('DCONF_PROFILE', None)
        subprocess.run(['dbus-run-session', '--', sys.executable, __file__],
                       env=environment, check=True)
    raise SystemExit(0)

root = Path(os.environ['ZDOTFILES_GNOME_TEST_ROOT'])
home = Path.home()
data = Path(os.environ['XDG_DATA_HOME'])
state = Path(os.environ['XDG_STATE_HOME'])
extensions = data / 'gnome-shell/extensions'
font_relative = Path('fontconfig/conf.d/60-jetbrainsmono-thai.conf')
font_source = REPO / '.config' / font_relative
font_config = Path(os.environ['XDG_CONFIG_HOME']) / font_relative
uuid = 'super-o-search@codex.local'
wm = 'org.gnome.desktop.wm.keybindings'
shell = 'org.gnome.shell'


def run(action, *options, success=True, extra=None):
    result = subprocess.run([str(REPO / 'zdotfiles'), action, '--only', 'gnome', *options],
                            env=dict(os.environ) | (extra or {}), capture_output=True, text=True)
    assert (result.returncode == 0) == success, result.stdout + result.stderr
    return result.stdout + result.stderr


def set_value(schema, key, value):
    subprocess.run(['gsettings', 'set', schema, key, value], check=True)


def get_value(schema, key):
    return subprocess.check_output(['gsettings', 'get', schema, key], text=True).strip()


def snapshots():
    return sorted(state.glob('zdotfiles/backups/*/gnome-*/snapshot.json'))


output = run('setup', '--dry-run')
assert 'would install GNOME extension' in output and 'would set ' in output
assert 'would install GNOME font fallback' in output
assert not font_config.exists()
assert not extensions.exists() and not state.exists(), 'dry run must not deploy or back up'
run('verify', success=False)
assert not extensions.exists() and not state.exists(), 'verify must remain read-only'
assert not font_config.exists()

# Existing user shortcuts, other extensions, and wallpaper survive setup.
set_value(wm, 'switch-to-workspace-left', "['<Super>b', '<Alt>F1']")
set_value(wm, 'switch-to-workspace-right', "['<Super>n', '<Alt>F2']")
set_value('org.gnome.shell.keybindings', 'toggle-message-tray', "['<Super>m', '<Super>v', '<Alt>F3']")
set_value('org.gnome.shell.keybindings', 'focus-active-notification', "['<Super>n', '<Alt>F4']")
set_value(shell, 'enabled-extensions', "['keep@tests.local', 'overview-keys@znnn.local']")
set_value(shell, 'disabled-extensions', "['super-o-search@codex.local', 'disabled@tests.local']")
set_value('org.gnome.shell.keybindings', 'toggle-overview', "['<Super>o', '<Alt>F5']")
set_value(shell, 'disable-user-extensions', 'true')
set_value('org.gnome.desktop.background', 'picture-uri', "'file:///keep-wallpaper.png'")
set_value('org.gnome.desktop.interface', 'font-name', "'Existing Font 10'")
stale = extensions / uuid / 'extension.js'
stale.parent.mkdir(parents=True)
stale.write_text('// existing extension payload\n')
unrelated = stale.parent / 'keep.txt'
unrelated.write_text('keep unrelated files\n')
font_config.parent.mkdir(parents=True)
old_font_config = '<?xml version="1.0"?><fontconfig/>\n'
font_config.write_text(old_font_config)
unrelated_font = font_config.with_name('99-keep.conf')
unrelated_font.write_text(old_font_config)
run('setup', '--dry-run')
run('verify', success=False)
assert 'overview-keys@znnn.local' in get_value(shell, 'enabled-extensions')
assert '<Super>o' in get_value('org.gnome.shell.keybindings', 'toggle-overview')
assert stale.read_text() == '// existing extension payload\n'
assert font_config.read_text() == old_font_config
assert not snapshots(), 'migration preview and verify must remain read-only'
run('setup')
run('verify')
assert get_value(wm, 'switch-to-workspace-left') == "['<Alt>F1', '<Super>n']"
assert get_value(wm, 'switch-to-workspace-right') == "['<Alt>F2', '<Super>m']"
assert get_value('org.gnome.shell.keybindings', 'toggle-message-tray') == "['<Super>v', '<Alt>F3']"
assert get_value('org.gnome.shell.keybindings', 'focus-active-notification') == "['<Alt>F4']"
assert 'keep@tests.local' in get_value(shell, 'enabled-extensions')
assert 'overview-keys@znnn.local' not in get_value(shell, 'enabled-extensions')
assert 'overview-keys@znnn.local' in get_value(shell, 'disabled-extensions')
assert get_value('org.gnome.shell.keybindings', 'toggle-overview') == "['<Alt>F5']"
assert uuid not in get_value(shell, 'disabled-extensions')
assert 'disabled@tests.local' in get_value(shell, 'disabled-extensions')
assert get_value(shell, 'disable-user-extensions') == 'false'
assert get_value('org.gnome.desktop.background', 'picture-uri') == "'file:///keep-wallpaper.png'"
assert unrelated.read_text() == 'keep unrelated files\n'
assert (extensions / uuid / 'schemas/gschemas.compiled').is_file()
assert font_config.read_bytes() == font_source.read_bytes()
assert unrelated_font.read_text() == old_font_config
assert not (home / '.config' / font_relative).exists(), 'must honor XDG_CONFIG_HOME'
assert not (home / '.config/nvim').exists() and not (home / '.config/Code').exists()
snapshot = json.loads(snapshots()[0].read_text())
accent = next(row for row in snapshot['settings'] if row['key'] == 'accent-color')
assert accent['user_value'] is None, 'backup must distinguish default from explicit override'
font = next(row for row in snapshot['settings'] if row['key'] == 'font-name')
assert font['user_value'] == "'Existing Font 10'"
enabled = next(row for row in snapshot['settings'] if row['key'] == 'enabled-extensions')
assert 'overview-keys@znnn.local' in enabled['user_value']
toggle = next(row for row in snapshot['settings'] if row['key'] == 'toggle-overview')
assert toggle['user_value'] == "['<Super>o', '<Alt>F5']"
old_file = next(row for row in snapshot['files'] if row['destination'] == str(stale))
assert Path(old_file['backup']).read_text() == '// existing extension payload\n'
old_font = next(row for row in snapshot['files'] if row['destination'] == str(font_config))
assert Path(old_font['backup']).read_text() == old_font_config

# Fontconfig loads the deployed rule via XDG and keeps Latin's requested family
# first, followed immediately by the Thai fallback, ahead of generic defaults.
for family in ('JetBrainsMono Nerd Font', 'JetBrainsMono Nerd Font Mono'):
    for suffix in ('', ':weight=bold', ':lang=th'):
        result = subprocess.run(['fc-pattern', '-c', '-f', '%{family}', family + suffix],
                                capture_output=True, text=True, check=True)
        assert not result.stderr, result.stderr
        assert result.stdout.split(',')[:2] == [family, 'Noto Sans Thai'], result.stdout
before = snapshots()
run('setup')
run('verify')
assert snapshots() == before, 'unchanged setup must not create backups'

font_config.write_text(old_font_config)
output = run('verify', success=False)
assert 'different  GNOME font fallback' in output
run('setup', '--dry-run')
assert font_config.read_text() == old_font_config and snapshots() == before
run('setup', '--skip-extensions')
run('verify')
assert font_config.read_bytes() == font_source.read_bytes()
before = snapshots()

set_value('org.gnome.desktop.interface', 'accent-color', "'green'")
run('verify', success=False)
run('setup', '--dry-run')
assert get_value('org.gnome.desktop.interface', 'accent-color') == "'green'"
assert snapshots() == before
run('setup')
run('verify')
assert len(snapshots()) > len(before)

# Skip settings still repairs source; skip extensions leaves their files alone.
set_value('org.gnome.desktop.interface', 'accent-color', "'green'")
stale.write_text('// stale again\n')
font_config.write_text(old_font_config)
run('setup', '--skip-system-settings')
assert get_value('org.gnome.desktop.interface', 'accent-color') == "'green'"
assert stale.read_text() != '// stale again\n'
assert font_config.read_text() == old_font_config
run('verify', '--skip-system-settings')
stale.write_text('// keep when skipped\n')
set_value(shell, 'enabled-extensions', "['keep@tests.local', 'overview-keys@znnn.local']")
set_value('org.gnome.shell.keybindings', 'toggle-overview', "['<Super>o', '<Alt>F5']")
run('setup', '--skip-extensions')
run('verify', '--skip-extensions')
assert font_config.read_bytes() == font_source.read_bytes()
assert stale.read_text() == '// keep when skipped\n'
assert 'overview-keys@znnn.local' in get_value(shell, 'enabled-extensions')
assert '<Super>o' in get_value('org.gnome.shell.keybindings', 'toggle-overview')
run('verify', '--skip-extensions', '--skip-system-settings')

# Another home receives only files and uses its own conventional data path.
alternate = root / 'alternate'
set_value('org.gnome.desktop.interface', 'accent-color', "'green'")
run('setup', '--home', str(alternate), '--dry-run')
assert not alternate.exists()
run('setup', '--home', str(alternate))
run('verify', '--home', str(alternate))
assert (alternate / '.local/share/gnome-shell/extensions' / uuid / 'extension.js').is_file()
alternate_font = alternate / '.config' / font_relative
assert alternate_font.read_bytes() == font_source.read_bytes()
alternate_snapshot = next((alternate / '.local/state/zdotfiles/backups').glob('*/gnome-*/snapshot.json'))
font_record = next(row for row in json.loads(alternate_snapshot.read_text())['files']
                   if row['destination'] == str(alternate_font))
assert font_record['backup'] is None, 'new font config backup must record absence'
assert get_value('org.gnome.desktop.interface', 'accent-color') == "'green'"

# Unsupported Shell versions stop before deployment or settings writes.
commands = root / 'commands'
commands.mkdir()
fake_shell = commands / 'gnome-shell'
fake_shell.write_text('#!/bin/sh\necho "GNOME Shell 99.0"\n')
fake_shell.chmod(0o755)
before = stale.read_bytes()
font_config.write_text(old_font_config)
output = run('setup', success=False, extra={'PATH': str(commands) + os.pathsep + os.environ['PATH']})
assert 'supports GNOME' in output
assert stale.read_bytes() == before
assert font_config.read_text() == old_font_config
assert get_value('org.gnome.desktop.interface', 'accent-color') == "'green'"
print('GNOME integration passed: dry run, verify, merge, migration, backups, repeat setup, drift repair, font fallback, skip options, alternate home, version guard')
