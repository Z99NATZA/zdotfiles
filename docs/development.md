# Development

## Checks

Validate the installer, test the local VS Code extension, and compare the
repository with the current machine:

```bash
# ---------- bash ---------- #

bash -n ./zdotfiles
node .vscode/extensions/znnn.focused-pane-resizer-0.1.0/test.js
./zdotfiles verify
git diff --check
```

Validate JSON files with `jq` when it is available:

```bash
# ---------- bash ---------- #

jq empty .config/Code/User/keybindings.json
jq empty .vscode/extensions/znnn.focused-pane-resizer-0.1.0/package.json
jq empty .config/nvim/lazy-lock.json
```

When Neovim is installed, check the Lua config without loading plugins:

```bash
nvim --headless -u NONE -c "lua assert(loadfile('.config/nvim/init.lua'))" -c 'qa!'
```

`settings.json` is JSON with Comments and may include trailing commas, so it
is not expected to pass a strict JSON parser unchanged.

## Maintenance

- Keep live files and their repository copies synchronized.
- Add deployed files to the relevant
  [VS Code](../manifest/vscode-files.txt) or
  [Neovim](../manifest/nvim-files.txt) manifest.
- Add Marketplace extensions to
  [manifest/vscode-extensions.txt](../manifest/vscode-extensions.txt).
- Run `setup --dry-run` before applying changes on another machine.
- Run the extension tests after changing pane or sidebar resize behavior.
