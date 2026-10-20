# Configuration

## Requirements

```text
Target
==========
Ubuntu 26.04 LTS, Bash, and core utilities.
Install editor packages separately. Neovim setup only uses existing dependencies.

VS Code
----------
code + Python 3: local and Marketplace extensions.
GNOME/IBus: optional desktop shortcut setting.
Standard ~/.vscode/extensions only; custom profiles and portable installs are unsupported.

Neovim
----------
Required: Neovim >= 0.11.2, Git, C compiler, curl, tar.
Optional: ripgrep, rust-analyzer, basedpyright-langserver, clipboard tools.
Tested on Ubuntu 26.04 with Neovim 0.11.6 and 0.12.5.
Wayland: wl-clipboard. X11: xclip or xsel. Missing clipboard tools do not block setup.
```

## Setup

```bash
# ---------- bash ---------- #

# Preview, install, and verify both editors
./zdotfiles setup --dry-run
./zdotfiles setup
./zdotfiles verify

# Manage one editor
./zdotfiles setup --only nvim
./zdotfiles verify --only nvim
```

| Option | Effect |
|---|---|
| `--only nvim\|vscode` | Select an editor; default is both |
| `--home PATH` | Deploy configuration to another absolute home path |
| `--dry-run` | Preview setup without changes |
| `--skip-extensions` | Skip VS Code extension installation/checks |
| `--skip-system-settings` | Skip GNOME/IBus changes/checks |

## Files and Backups

```text
Deployment
==========
Manifest paths are relative to $HOME. Unrelated files are retained.
Changed configuration files are backed up before replacement.
Extension updates use the VS Code CLI, not file backups.

Backup locations
----------
Current home: ${XDG_STATE_HOME:-$HOME/.local/state}/zdotfiles/backups/<timestamp>/
Other home:   PATH/.local/state/zdotfiles/backups/<timestamp>/

Alternate home
----------
--home targeting another user copies configuration only.
Prepare dependencies separately, then run setup as that user for extensions and Neovim plugins/parsers.
Neovim requires default XDG_CONFIG_HOME and NVIM_APPNAME;
custom XDG data, state, and cache directories are supported.
```

Manifests: [VS Code files](../manifest/vscode-files.txt),
[Neovim files](../manifest/nvim-files.txt),
[Marketplace extensions](../manifest/vscode-extensions.txt).

## Neovim

```text
Setup
==========
Checks required programs, restores plugins to lazy-lock.json commits,
installs parsers, and loads the configuration headlessly.
Requires network access; preserves the lockfile and refuses to discard local plugin edits.
System packages and Rust toolchains are not locked by this repository.

Parsers
----------
Lua, Vim, Vim help, Tree-sitter queries, Python, Rust, Bash, JSON.
The list is maintained in init.lua.
```

```bash
# ---------- bash ---------- #

# Preview configuration and runtime setup
./zdotfiles setup --only nvim --dry-run

# Set up config, plugins, and parsers as your normal user
make setup-nvim

# Verify files, required dependencies, and runtime
./zdotfiles verify --only nvim
```

```text
Dependencies
==========
Setup never invokes sudo, apt, or language-server installers.
Missing required programs stop setup before config deployment, including dry runs.
Missing optional tools produce notices; setup and verify continue.
Rust/Python LSP is enabled only when its server is available.
A rustup proxy without a working rust-analyzer is treated as unavailable.

Existing managed tools
----------
Tools installed by earlier versions remain under
${XDG_DATA_HOME:-$HOME/.local/share}/zdotfiles/.
Neovim and the installer include that bin directory in their own PATH.
No installed tools are removed and no shell profiles are changed.
```

Package commands: [README](../README.md).

References: [Ubuntu Neovim package](https://packages.ubuntu.com/neovim),
[Basedpyright installation](https://docs.basedpyright.com/dev/installation/command-line-and-language-server/).

## VS Code and Desktop

```text
Extensions
==========
Installs/repairs znnn.focused-pane-resizer and Marketplace extensions via code.
Skipped without code, with --skip-extensions, or for another --home.
After installation: Developer: Reload Window.

Wallpaper
----------
background.fullscreen.images points below /home/znnn/Pictures/.
Create that path or update the setting on other machines.

IBus
----------
VS Code setup moves the emoji shortcut to Super+; to free Super+.
Skipped without the schema, with --skip-system-settings, for another --home,
or when managing only Neovim.
```

## Verification

| Area | Checks |
|---|---|
| Files | Match repository contents |
| Neovim | Dependencies, plugin commits, parser loading/highlighting, config errors |
| VS Code | Local extension registration/content/version/removal state; Marketplace installation |
| IBus | Emoji shortcut, when available |

```text
Limits
==========
A failed check returns a nonzero exit status.
Neovim verification does not download plugins or parsers.
Runtime checks apply to the current home only.
Headless checks do not test clipboard transfer or LSP attachment.
VS Code checks installation, not activation or keyboard behavior.
```
