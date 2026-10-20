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

# Dependency installation with fake package managers (Ubuntu 26.04)
PYTHONDONTWRITEBYTECODE=1 python3 tests/nvim-dependencies.py

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
| Dependency provisioning | Python 3, Ubuntu 26.04 | Dry run, read-only verify, failed install, repeat setup, clipboard, alternate home |
| Neovim integration | Python 3, Neovim dependencies, network | Clean/repeat setup, dry run, commit drift/repair, missing parser, config errors |

```text
Isolation
==========
VS Code tests use temporary extension/user-data directories and stub Marketplace listings.
Dependency tests use fake package managers; they never invoke real sudo or downloads.
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
