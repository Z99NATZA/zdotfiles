# Configuration

## Requirements

Setup requires Linux, Bash, standard core utilities, and Visual Studio Code.
The `code` command is optional and installs Marketplace extensions. GNOME and
IBus are optional for the desktop keyboard setting.

## Setup Options

Run `./zdotfiles help` for the complete command list. Useful options are:

```text
--dry-run               Preview setup without changing files
--home PATH             Install below another home directory
--skip-extensions       Skip Marketplace extensions
--skip-system-settings  Skip the GNOME/IBus setting
```

## Managed Files

The repository mirrors paths below `$HOME`. The installer deploys only the
paths listed in [manifest/files.txt](../manifest/files.txt) and never removes
unrelated files.

When a destination differs from the repository, `setup` moves the original to
a timestamped backup before installing the new file. For the current user, the
backup root is:

```text
${XDG_STATE_HOME:-$HOME/.local/state}/zdotfiles/backups/
```

When `--home PATH` targets another home directory, backups are stored below
`PATH/.local/state/zdotfiles/backups/`.

## VS Code

Setup installs the following configuration below the target home:

```text
.config/Code/User/keybindings.json
.config/Code/User/settings.json
.vscode/extensions/znnn.focused-pane-resizer-0.1.0/
```

The local `znnn.focused-pane-resizer` extension is copied directly from this
repository. Marketplace extensions are listed in
[manifest/vscode-extensions.txt](../manifest/vscode-extensions.txt) and are
installed with the `code` command.

Marketplace extensions are skipped when `code` is unavailable, when
`--skip-extensions` is used, or when `--home` does not target the current
`HOME`.

The stored VS Code settings include an absolute wallpaper path below
`/home/znnn/Pictures/`. Create the same path on another machine or update
`background.fullscreen.images` after setup.

## GNOME and IBus

When the IBus schema is available, setup reserves `Super+.` for VS Code by
keeping the IBus emoji shortcut on `Super+;`.

System settings are skipped when the schema is unavailable, when
`--skip-system-settings` is used, or when `--home` does not target the current
`HOME`.

## Verification

`verify` compares every managed file with the repository. For the current
home, it also checks Marketplace extensions and the IBus setting when those
tools are available.

```bash
# ---------- bash ---------- #

./zdotfiles verify
```
