#!/usr/bin/env python3
"""Package and install the bundled extension using the VS Code CLI."""
import argparse
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import xml.etree.ElementTree as ET
import zipfile

SOURCE = Path(__file__).resolve().parents[1] / '.vscode/extensions/znnn.focused-pane-resizer-0.1.0'
FILES = ('package.json', 'extension.js', 'resize-layout.js', 'sidebar-resize.js')


def installed(source, extensions):
    package = json.loads((source / 'package.json').read_text())
    identity = package['publisher'] + '.' + package['name']
    try:
        registry = json.loads((extensions / 'extensions.json').read_text())
        obsolete = json.loads((extensions / '.obsolete').read_text()) if (extensions / '.obsolete').exists() else {}
        for entry in registry:
            if entry['identifier']['id'].lower() != identity.lower() or entry['version'] != package['version']:
                continue
            location = Path(entry['location']['path'])
            if obsolete.get(location.name):
                continue
            deployed = json.loads((location / 'package.json').read_text())
            # VS Code adds installation metadata to package.json.
            deployed.pop('__metadata', None)
            if deployed != package:
                continue
            if all((location / name).read_bytes() == (source / name).read_bytes() for name in FILES if name != 'package.json'):
                return True
    except (OSError, ValueError, KeyError, TypeError):
        return False
    return False


def package_vsix(source, destination):
    package = json.loads((source / 'package.json').read_text())
    root = ET.Element('PackageManifest', {'Version': '2.0.0', 'xmlns': 'http://schemas.microsoft.com/developer/vsx-schema/2011'})
    metadata = ET.SubElement(root, 'Metadata')
    ET.SubElement(metadata, 'Identity', {'Language': 'en-US', 'Id': package['name'], 'Version': package['version'], 'Publisher': package['publisher']})
    ET.SubElement(metadata, 'DisplayName').text = package['displayName']
    ET.SubElement(metadata, 'Description', {'xml:space': 'preserve'}).text = package['description']
    properties = ET.SubElement(metadata, 'Properties')
    ET.SubElement(properties, 'Property', {'Id': 'Microsoft.VisualStudio.Code.Engine', 'Value': package['engines']['vscode']})
    installation = ET.SubElement(root, 'Installation')
    ET.SubElement(installation, 'InstallationTarget', {'Id': 'Microsoft.VisualStudio.Code'})
    ET.SubElement(root, 'Dependencies')
    assets = ET.SubElement(root, 'Assets')
    ET.SubElement(assets, 'Asset', {'Type': 'Microsoft.VisualStudio.Code.Manifest', 'Path': 'extension/package.json', 'Addressable': 'true'})
    types = ET.Element('Types', {'xmlns': 'http://schemas.openxmlformats.org/package/2006/content-types'})
    for extension, content_type in [('json', 'application/json'), ('js', 'application/javascript'), ('vsixmanifest', 'text/xml')]:
        ET.SubElement(types, 'Default', {'Extension': extension, 'ContentType': content_type})
    with zipfile.ZipFile(destination, 'w', zipfile.ZIP_DEFLATED) as archive:
        archive.writestr('extension.vsixmanifest', ET.tostring(root, encoding='utf-8', xml_declaration=True))
        archive.writestr('[Content_Types].xml', ET.tostring(types, encoding='utf-8', xml_declaration=True))
        for name in FILES:
            archive.write(source / name, 'extension/' + name)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', choices=('setup', 'verify'))
    parser.add_argument('--dry-run', action='store_true')
    args = parser.parse_args()
    extensions = Path.home() / '.vscode/extensions'
    identity = 'znnn.focused-pane-resizer'
    if installed(SOURCE, extensions):
        print(f'{"ok" if args.action == "verify" else "unchanged"}  VS Code extension {identity}', flush=True)
        return 0
    if args.action == 'verify':
        print(f'missing or outdated  VS Code extension {identity} (registration, removal state, or contents)')
        return 1
    if args.dry_run:
        print(f'would package and install VS Code extension {identity}')
        return 0
    with tempfile.TemporaryDirectory(prefix='zdotfiles-vsix-') as temporary:
        vsix = Path(temporary) / (identity + '.vsix')
        package_vsix(SOURCE, vsix)
        subprocess.run(['code', '--extensions-dir', str(extensions), '--install-extension', str(vsix), '--force'], check=True)
    if not installed(SOURCE, extensions):
        raise RuntimeError('VS Code installation did not register the bundled extension correctly')
    print(f'installed  VS Code extension {identity}; run Developer: Reload Window in open VS Code windows')
    return 0


if __name__ == '__main__':
    try:
        sys.exit(main())
    except (OSError, ValueError, subprocess.CalledProcessError, RuntimeError) as error:
        print(f'zdotfiles: {error}', file=sys.stderr)
        sys.exit(1)
