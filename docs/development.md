# Development

## Checks

```bash
# ---------- bash ---------- #

# Installer syntax and whitespace
bash -n ./zdotfiles scripts/nvim-dependencies.sh
git diff --check

# VS Code extension and installer integration
PYTHONDONTWRITEBYTECODE=1 python3 tests/local-extension.py
node .vscode/extensions/znnn.focused-pane-resizer-0.1.0/test.js

# Required/optional dependency checks; package installers are forbidden
PYTHONDONTWRITEBYTECODE=1 python3 tests/nvim-dependencies.py

# GNOME deployment with isolated home, XDG paths, D-Bus and dconf database
PYTHONDONTWRITEBYTECODE=1 python3 tests/gnome.py

# Overview app launching without changing the desktop session
node --experimental-vm-modules tests/gnome-overview.js

# Load config without language servers, including a broken rustup proxy
nvim --headless -u NONE -i NONE -l tests/nvim-optional.lua

# Neovim integration in an isolated home
PYTHONDONTWRITEBYTECODE=1 python3 tests/nvim.py

# Compare the active installation with the repository
./zdotfiles verify

# Strict JSON; requires jq
jq empty .config/Code/User/keybindings.json
jq empty .vscode/extensions/znnn.focused-pane-resizer-0.1.0/package.json
jq empty .config/nvim/lazy-lock.json

# Lua syntax without loading plugins
nvim --headless -u NONE -c "lua assert(loadfile('.config/nvim/init.lua'))" -c 'qa!'
```

| Suite | Requirements | Coverage |
|---|---|---|
| VS Code integration | Python 3, `code` | VSIX repair, setup/verify, repeat setup, dry run, skip options, editor selection, alternate home |
| Dependency checks | Python 3, Bash | No package installation; required/optional tools, old Neovim, dry run, clipboard, alternate home |
| Neovim integration | Python 3, Neovim dependencies, network | Clean/repeat setup, dry run, commit drift/repair, missing parser, config errors |
| GNOME integration | Python 3 + PyGObject, GNOME 50, D-Bus, dconf, glib-compile-schemas | Dry run, verify, shortcut/extension merging, workspace shortcut migration, notification conflicts, backups, drift repair, skip flags, alternate home, version guard |
| GNOME Overview | Node.js with VM modules | New-window desktop actions, running apps, normal activation fallback, selected results, stale search, held Enter |

```text
Isolation
==========
VS Code tests use temporary extension/user-data directories and stub Marketplace listings.
Dependency tests fail if setup/verify invokes any package installer.
GNOME tests use a separate session bus and temporary dconf database, leaving
the desktop session unchanged. They do not launch or exercise the Shell UI.
Overview tests load the shipped extension with stubbed Shell actors/apps;
they do not prove that GNOME loaded it or that an app's desktop action works.
Neovim tests use a temporary home; preinstall dependencies before running the real integration suite.

JSON
----------
settings.json uses JSON with Comments; do not validate it as strict JSON.
```

## Maintenance

```text
Workflow
==========
Keep deployed files and repository copies synchronized.
Update manifests when adding managed files or Marketplace extensions.
Preview setup before deploying to another machine.
Run extension tests after changing pane/sidebar resizing.
```

References: [Dependencies](configuration.md), [Docs format](docs-format-guide.md),
[VS Code files](../manifest/vscode-files.txt), [Neovim files](../manifest/nvim-files.txt),
[Extensions](../manifest/vscode-extensions.txt).
