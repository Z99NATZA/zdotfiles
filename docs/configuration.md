# Configuration

## Requirements

```text
Target
==========
Ubuntu 26.04 LTS, Bash, and core utilities.
Install editor packages separately. Neovim setup only uses existing dependencies.

GNOME
----------
Python 3 + PyGObject, GNOME schemas, and your logged-in session D-Bus.
Custom extensions support GNOME Shell 50 and require glib-compile-schemas.
Install fonts and themes separately; setup never installs system packages.

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

### Ubuntu packages

```bash
# ---------- bash ---------- #

# Required for Neovim setup
sudo apt update
sudo apt install neovim git build-essential curl tar make

# Optional search and desktop clipboard tools
sudo apt install ripgrep
sudo apt install wl-clipboard  # Wayland
sudo apt install xclip         # X11

# GNOME profile, when these desktop dependencies are not already installed
sudo apt install python3-gi libglib2.0-bin gnome-shell

# Optional Rust language server
sudo apt install rustup
rustup toolchain install stable --profile minimal --component rust-analyzer
rustup default stable  # only when no default toolchain is configured

# Optional Python language server
sudo apt install pipx
pipx install basedpyright==1.40.2
pipx ensurepath
```

For an existing default Rust toolchain, run
`rustup component add rust-analyzer`. Open a new login shell after
`pipx ensurepath`, then reopen Neovim. Language servers must be on `PATH`.

```bash
# ---------- bash ---------- #

# Preview, install, and verify editors and GNOME
./zdotfiles setup --dry-run
./zdotfiles setup
./zdotfiles verify

# Manage one editor
./zdotfiles setup --only nvim
./zdotfiles verify --only nvim
```

| Option | Effect |
|---|---|
| `--only nvim\|vscode\|gnome` | Select a component; default is all three |
| `--home PATH` | Deploy configuration to another absolute home path |
| `--dry-run` | Preview setup without changes |
| `--skip-extensions` | Skip VS Code and GNOME extension installation/checks |
| `--skip-system-settings` | Skip GNOME/IBus settings; extension source files can still be deployed |

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

GNOME snapshots
----------
Changed GNOME settings and extension files are backed up under
<timestamp>/gnome-<unique-id>/snapshot.json and files/.
user_value records the previous explicit GVariant override; null means the
setting previously used its default. effective_value records what it resolved to.
For manual restoration, use gsettings set with user_value, or gsettings reset
for null. File records identify the original destination and saved file;
a null file backup means the destination did not previously exist.
Unchanged setup and dry runs do not create snapshots.

Alternate home
----------
--home targeting another user copies configuration only.
Prepare dependencies separately, then run setup as that user for extensions and Neovim plugins/parsers.
Neovim requires default XDG_CONFIG_HOME and NVIM_APPNAME;
custom XDG data, state, and cache directories are supported.
GNOME honors XDG_DATA_HOME/XDG_STATE_HOME for the current user. Another --home
receives extension source files under .local/share only, with no session settings,
schema compilation, or extension activation.
```

Manifests: [VS Code files](../manifest/vscode-files.txt),
[Neovim files](../manifest/nvim-files.txt),
[Marketplace extensions](../manifest/vscode-extensions.txt).

## GNOME

```bash
# ---------- bash ---------- #

./zdotfiles setup --only gnome --dry-run
make setup-gnome
./zdotfiles verify --only gnome

# Settings only, or extension files only
./zdotfiles setup --only gnome --skip-extensions
./zdotfiles setup --only gnome --skip-system-settings
```

```text
Managed profile
==========
manifest/gnome-settings.json selects 33 deliberate desktop preferences:
dark/purple appearance, Adwaita cursor, JetBrainsMono Nerd Font, US/Thai input,
Ctrl+Shift input switching, keyboard repeat, idle/power behavior,
window shortcuts, empty pinned apps, and hiding the Home desktop icon.
Themes: Yaru-purple-dark. Fonts: JetBrainsMono Nerd Font / Nerd Font Mono.
These resources must already be installed; GNOME may fall back if unavailable.
Mouse speed is configured separately on each machine and is not managed.

Shortcut lists
----------
Super+N goes left; Super+M goes right. Old left Super+B and right Super+N
workspace bindings are removed. Super+N is removed from notification focus;
Super+M is removed from the notification tray; Super+V remains available.
Lists append/remove only managed shortcuts and preserve unrelated alternatives.
Other list settings, such as the chosen input sources, replace that preference.

Custom extensions
----------
Super O Search: Super+O opens Overview with keyboard window selection.
Enter on a search app opens a new window when the app exposes a new-window
desktop action, or when a running app supports new windows. Other apps use
normal activation. The selected app result takes precedence over the first app.
Desktop actions remain owned by each app: zter's launcher runs zter --standalone.
Hide Top Bar: hides the GNOME top bar and releases its reserved screen space.
Source files live under .local/share/gnome-shell/extensions/ in this repository.
Enabled extension UUIDs merge with the existing list; unrelated extensions and
their enabled/disabled state are retained. The conflicting local extension
overview-keys@znnn.local is disabled; its files remain in place. Super+O is
removed from GNOME's toggle-overview binding so Super O Search owns that shortcut;
other toggle-overview shortcuts are preserved. Both migrations are backed up
and skipped with --skip-extensions or --skip-system-settings.
The master user-extension switch is enabled when applying the custom extensions.

Lifecycle
----------
Setup copies source files and compiles schemas; generated caches are not tracked.
Settings apply immediately. Log out/in to load newly installed or updated
extension code. Verify checks files, compiled schema freshness, configured
extension UUIDs and settings; it does not prove that Shell loaded the new code.
An unsupported Shell version stops extension deployment; --skip-extensions
allows applying the core settings independently.
Unavailable schemas/keys are reported and skipped. Locked settings stop setup.

Scope
----------
The profile does not include wallpaper, Zhyprbola, application history, or the
app-picker layout. Zhyprbola is installed and configured from its own repository.
No GNOME settings are applied while selecting only Neovim or VS Code; the
existing optional VS Code IBus emoji setting remains managed by VS Code setup.
```

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
| GNOME | Managed settings, source files, schema freshness, configured extension UUIDs |

```text
Limits
==========
A failed check returns a nonzero exit status.
Neovim verification does not download plugins or parsers.
Runtime checks apply to the current home only.
Headless checks do not test clipboard transfer or LSP attachment.
VS Code checks installation, not activation or keyboard behavior.
```
