"""Deploy the GNOME profile without replacing the user's complete dconf database."""
import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import time

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / '.local/share/gnome-shell/extensions'
MANIFEST = ROOT / 'manifest/gnome-settings.json'


class Backup:
    def __init__(self, root):
        self.path = root / f'gnome-{time.time_ns()}'
        self.records = {'settings': [], 'files': []}

    def save(self):
        self.path.mkdir(parents=True, exist_ok=True, mode=0o700)
        staged = self.path / 'snapshot.json.tmp'
        staged.write_text(json.dumps(self.records, indent=2) + '\n')
        staged.chmod(0o600)
        staged.replace(self.path / 'snapshot.json')

    def setting(self, schema, key, settings):
        user = settings.get_user_value(key)
        self.records['settings'].append({
            'schema': schema, 'key': key,
            'user_value': None if user is None else user.print_(True),
            'effective_value': settings.get_value(key).print_(True),
        })
        self.save()

    def file(self, destination, relative):
        saved = self.path / 'files' / relative
        existed = destination.exists() or destination.is_symlink()
        if existed:
            saved.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(destination, saved, follow_symlinks=False)
        self.records['files'].append({
            'destination': str(destination),
            'backup': str(saved) if existed else None,
        })
        self.save()


def extension_files(manifest, destination):
    for uuid in manifest['extensions']:
        for source in sorted((SOURCE / uuid).rglob('*')):
            if source.is_file() and source.name != 'gschemas.compiled':
                relative = source.relative_to(SOURCE)
                yield source, destination / relative, relative


def deploy_extensions(args, manifest, destination, backup):
    if args.skip_extensions:
        return True
    files = list(extension_files(manifest, destination))
    for uuid in manifest['extensions']:
        metadata = json.loads((SOURCE / uuid / 'metadata.json').read_text())
        if metadata['uuid'] != uuid:
            raise ValueError(f'extension UUID mismatch: {uuid}')
    if args.current_home:
        shell = shutil.which('gnome-shell')
        if not shell:
            raise ValueError('gnome-shell is required for GNOME extensions; use --skip-extensions')
        major = subprocess.check_output([shell, '--version'], text=True).split()[-1].split('.')[0]
        for uuid in manifest['extensions']:
            versions = json.loads((SOURCE / uuid / 'metadata.json').read_text())['shell-version']
            if major not in versions:
                raise ValueError(f'{uuid} supports GNOME {versions}, found {major}; use --skip-extensions')
        if not shutil.which('glib-compile-schemas'):
            raise ValueError('glib-compile-schemas is required for GNOME extensions')
    valid = True
    for source, target, relative in files:
        identical = target.is_file() and source.read_bytes() == target.read_bytes()
        if identical:
            print(f'{"ok" if args.action == "verify" else "unchanged"}  GNOME extension {relative}')
        elif args.action == 'verify':
            print(f'different  GNOME extension {relative}')
            valid = False
        elif args.dry_run:
            print(f'would install GNOME extension {relative}')
        else:
            backup.file(target, relative)
            target.parent.mkdir(parents=True, exist_ok=True)
            with tempfile.NamedTemporaryFile(dir=target.parent, delete=False) as staged:
                staged.write(source.read_bytes())
                staged_path = Path(staged.name)
            try:
                staged_path.chmod(source.stat().st_mode & 0o777)
                staged_path.replace(target)
            finally:
                staged_path.unlink(missing_ok=True)
            print(f'installed  GNOME extension {relative}')
    # Another --home receives source files only, never session changes.
    if args.current_home:
        for uuid in manifest['extensions']:
            directory = destination / uuid / 'schemas'
            if not (SOURCE / uuid / 'schemas').exists():
                continue
            compiled = directory / 'gschemas.compiled'
            if args.action == 'verify':
                if not compiled.is_file() or any(
                    path.stat().st_mtime_ns > compiled.stat().st_mtime_ns
                    for path in directory.glob('*.gschema.xml')
                ):
                    print(f'different  GNOME compiled schemas: {uuid}')
                    valid = False
            elif args.dry_run:
                print(f'would compile GNOME extension schemas: {uuid}')
            elif not compiled.is_file() or any(
                path.stat().st_mtime_ns > compiled.stat().st_mtime_ns
                for path in directory.glob('*.gschema.xml')
            ):
                subprocess.run(['glib-compile-schemas', '--strict', str(directory)], check=True)
    return valid


def desired_value(GLib, settings, schema, item):
    value_type = schema.get_key(item['key']).get_value_type()
    value = GLib.Variant.parse(value_type, item['value'], None, None)
    operation = item.get('op', 'set')
    if operation == 'set':
        return value
    if operation not in ('append', 'remove') or value_type.dup_string() != 'as':
        raise ValueError(f'invalid setting operation: {item}')
    current = settings.get_strv(item['key'])
    wanted = value.unpack()
    if operation == 'append':
        removed = {key.lower() for key in item.get('remove', [])}
        current = [key for key in current if key.lower() not in removed]
        result = list(dict.fromkeys([*current, *wanted]))
    else:
        removed = {key.lower() for key in wanted}
        result = [key for key in current if key.lower() not in removed]
    return GLib.Variant('as', result)


def manage_settings(args, manifest, destination, backup):
    if args.skip_system_settings or not args.current_home:
        print('skipped    GNOME settings (--skip-system-settings or another --home)')
        return True
    from gi.repository import Gio, GLib

    source = Gio.SettingsSchemaSource.get_default()
    if not source.lookup('org.gnome.desktop.interface', True):
        print('skipped    GNOME settings (GNOME schemas unavailable)')
        return True
    if not os.environ.get('DBUS_SESSION_BUS_ADDRESS') and os.environ.get('GSETTINGS_BACKEND') != 'memory':
        raise ValueError('run GNOME setup/verify from your logged-in user session')
    for uuid in manifest['extensions']:
        directory = destination / uuid / 'schemas'
        if (directory / 'gschemas.compiled').is_file():
            source = Gio.SettingsSchemaSource.new_from_directory(str(directory), source, False)
    items = list(manifest['settings'])
    if not args.skip_extensions:
        uuids = repr(manifest['extensions'])
        conflicts = manifest.get('extension_conflicts', [])
        items.extend([
            {'schema': 'org.gnome.shell', 'key': 'enabled-extensions', 'op': 'append',
             'value': uuids, 'remove': conflicts},
            {'schema': 'org.gnome.shell', 'key': 'disabled-extensions', 'op': 'append',
             'value': repr(conflicts), 'remove': manifest['extensions']},
            {'schema': 'org.gnome.shell', 'key': 'disable-user-extensions', 'value': 'false'},
            {'schema': 'org.gnome.shell.keybindings', 'key': 'toggle-overview',
             'op': 'remove', 'value': "['<Super>o']"},
            {'schema': 'org.gnome.shell.extensions.super-o-search', 'key': 'open-search', 'value': "['<Super>o']"},
        ])
    plan = []
    for item in items:
        name, key = item['schema'], item['key']
        schema = source.lookup(name, True)
        if schema is None or not schema.has_key(key):
            print(f'skipped    unavailable GNOME setting: {name} {key}')
            continue
        settings = Gio.Settings.new_full(schema, None, None)
        expected = desired_value(GLib, settings, schema, item)
        if not schema.get_key(key).range_check(expected):
            raise ValueError(f'GNOME value is out of range: {name} {key}')
        if settings.get_value(key).equal(expected):
            print(f'{"ok" if args.action == "verify" else "unchanged"}  {name} {key}')
            continue
        if args.action == 'setup' and not settings.is_writable(key):
            raise ValueError(f'GNOME setting is locked: {name} {key}')
        plan.append((name, key, settings, expected))
    if args.action == 'verify':
        for name, key, _, expected in plan:
            print(f'different  {name} {key}: expected {expected.print_(True)}')
        return not plan
    if args.dry_run:
        for name, key, _, expected in plan:
            print(f'would set  {name} {key} = {expected.print_(True)}')
        return True
    for name, key, settings, expected in plan:
        backup.setting(name, key, settings)
    applied = []
    try:
        for name, key, settings, expected in plan:
            old = settings.get_user_value(key)
            if not settings.set_value(key, expected):
                raise ValueError(f'cannot set GNOME setting: {name} {key}')
            applied.append((settings, key, old))
            print(f'installed  {name} {key}')
        Gio.Settings.sync()
    except Exception:
        for settings, key, old in reversed(applied):
            if old is None:
                settings.reset(key)
            else:
                settings.set_value(key, old)
        Gio.Settings.sync()
        raise
    return True


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', choices=('setup', 'verify'))
    parser.add_argument('--home', type=Path, required=True)
    parser.add_argument('--backup-root', type=Path, required=True)
    parser.add_argument('--dry-run', action='store_true')
    parser.add_argument('--skip-extensions', action='store_true')
    parser.add_argument('--skip-system-settings', action='store_true')
    args = parser.parse_args()
    args.current_home = args.home == Path.home()
    data = Path(os.environ.get('XDG_DATA_HOME', str(args.home / '.local/share'))) if args.current_home else args.home / '.local/share'
    destination = data / 'gnome-shell/extensions'
    backup = Backup(args.backup_root)
    manifest = json.loads(MANIFEST.read_text())
    try:
        valid = deploy_extensions(args, manifest, destination, backup)
        valid = manage_settings(args, manifest, destination, backup) and valid
    except (ValueError, ImportError, OSError, subprocess.CalledProcessError) as error:
        print(f'zdotfiles GNOME: {error}')
        return 1
    finally:
        if backup.path.exists():
            print(f'backup     {backup.path}')
    if args.action == 'setup' and not args.dry_run and not args.skip_extensions and args.current_home:
        print('GNOME extension source is installed; log out/in to load new or changed extension code.')
    return 0 if valid else 1


if __name__ == '__main__':
    raise SystemExit(main())
