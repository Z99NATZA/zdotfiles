# Configuration

## Requirements

Setup requires Linux, Bash, and standard core utilities. It copies editor
configuration but does not install VS Code or Neovim. The `code` command is
optional and installs local and Marketplace extensions. Local extension
installation and verification also require Python 3 (standard library only). GNOME and IBus are optional for
the desktop keyboard setting.

## Setup Options

Run `./zdotfiles help` for the complete command list. Useful options are:

```text
--dry-run               Preview setup without changing files
--home PATH             Install below another home directory
--only nvim|vscode       Manage only one editor; omitted means both
--skip-extensions       Skip all VS Code extensions
--skip-system-settings  Skip the GNOME/IBus setting
```

The same `--only` option works with `verify`. `--only nvim` does not access VS
Code or GNOME/IBus settings; `--only vscode` does not access Neovim files.

## Managed Files

The repository mirrors paths below `$HOME`. Configuration files are deployed from paths
listed in [manifest/vscode-files.txt](../manifest/vscode-files.txt) and
[manifest/nvim-files.txt](../manifest/nvim-files.txt), according to `--only`.
The local VS Code extension is installed separately through the CLI.
Setup never removes unrelated files.

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
```

Setup packages the local `znnn.focused-pane-resizer` extension into a temporary
VSIX and installs it with `code --install-extension`. The helper uses the
standard `~/.vscode/extensions` directory and registry; custom VS Code profiles,
portable installations, and alternative extension directories are not supported.
It skips an installation that already matches the source, and repairs missing
registration, removal markers, or outdated contents through the CLI. The old
copy-only deployment is upgraded through this same installation path.

Extension updates use the VS Code CLI rather than the configuration-file backup
mechanism above. Run `Developer: Reload Window` in open VS Code windows after
installation. Marketplace extensions are listed in
[manifest/vscode-extensions.txt](../manifest/vscode-extensions.txt) and are
installed with the `code` command.

All VS Code extensions are skipped when `code` is unavailable, when
`--skip-extensions` is used, or when `--home` does not target the current
`HOME`. An alternate `--home` deploys configuration files only.

The stored VS Code settings include an absolute wallpaper path below
`/home/znnn/Pictures/`. Create the same path on another machine or update
`background.fullscreen.images` after setup.

## Neovim

Setup copies `.config/nvim/init.lua` and `.config/nvim/lazy-lock.json` below
the target home. It does not install Neovim, plugins, or language servers.
On first launch, the configuration bootstraps lazy.nvim with Git and downloads
its plugins; this needs network access. The configuration was tested with
Neovim 0.12.4.

## GNOME and IBus

When the IBus schema is available, VS Code setup reserves `Super+.` for editor
shortcuts by keeping the IBus emoji shortcut on `Super+;`. Neovim-only setup
does not change this system setting.

System settings are skipped when the schema is unavailable, when
`--skip-system-settings` is used, or when `--home` does not target the current
`HOME`.

## Verification

`verify` compares every managed file with the repository. For the current
home, it also checks the local extension registration, removal state, version,
and packaged contents, plus Marketplace extensions and the IBus setting when
those tools are available. Extension verification checks installation on disk,
not activation or keyboard behavior.

```bash
# ---------- bash ---------- #

./zdotfiles verify
```
