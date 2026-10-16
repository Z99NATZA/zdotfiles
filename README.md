# zdotfiles

Portable Linux configuration for recreating the current VS Code setup on
another machine.

## Stack

```text
Shell:    Bash
Editor:   Visual Studio Code
Desktop:  GNOME / IBus (optional)
Version:  1.0.0
```

## Setup

```text
Install
==========

Preview the changes, apply the configuration, and verify the result. Run these
commands from the project directory.
```

```bash
# ---------- bash ---------- #

./zdotfiles setup --dry-run
./zdotfiles setup
./zdotfiles verify
```

```text
Backup
==========

Before replacing a different destination file, setup moves the original to a
timestamped directory under ~/.local/state/zdotfiles/backups/. Unrelated files
are never removed.
```

## Options

```bash
# ---------- bash ---------- #

# Deploy below another home directory
./zdotfiles setup --home /absolute/path

# Do not install VS Code Marketplace extensions
./zdotfiles setup --skip-extensions

# Do not change GNOME or IBus settings
./zdotfiles setup --skip-system-settings

# Show every command and option
./zdotfiles help
```

## Configuration

```text
Files
==========

The repository mirrors paths below $HOME. The files deployed by setup are
listed in manifest/files.txt.

Extensions
----------

The local znnn.focused-pane-resizer extension is copied directly from this
repository. Marketplace extensions are listed separately in
manifest/vscode-extensions.txt and installed with the `code` command.

Keyboard
==========

Super+. is reserved for resizing the VS Code sidebar. When the IBus schema is
available, setup keeps the emoji shortcut on Super+; so the keys do not
conflict.
```

## Versions

```text
Release
==========

VERSION identifies the current source. Keep historical releases as Git tags
instead of copying the source into v1, v2, and v3 directories. Setup always
installs the version in the currently checked-out commit or tag.
```

```bash
# ---------- bash ---------- #

git tag v1.0.0
git clone --branch v1.0.0 <repository-url> zdotfiles
```

## Development

```text
Checks
==========

Validate the installer, test the local VS Code extension, and compare the
repository with the current machine.
```

```bash
# ---------- bash ---------- #

bash -n ./zdotfiles
node .vscode/extensions/znnn.focused-pane-resizer-0.1.0/test.js
./zdotfiles verify
```
