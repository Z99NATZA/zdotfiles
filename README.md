# zdotfiles

## Ubuntu 26.04 packages

```text
Required for Neovim setup
==========
Neovim >= 0.11.2, Git, a C compiler, curl, and tar.
Bash, core utilities, and make are needed to run make setup-nvim.
Prepare missing packages separately; skip this step if they are already installed.
Package commands below change the system and require administrator access.
```

```bash
# ---------- bash ---------- #

# Manual preparation only; setup never runs these commands
sudo apt update
sudo apt install neovim git build-essential curl tar make
```

## Optional tools

| Tool | Purpose |
|---|---|
| `ripgrep` | Text search |
| `rust-analyzer` | Rust language features |
| `basedpyright-langserver` | Python language features |
| `wl-clipboard` / `xclip` | Wayland / X11 clipboard; unnecessary for basic SSH editing |

```bash
# ---------- bash ---------- #

# Choose only the tools you need
sudo apt install ripgrep
sudo apt install wl-clipboard  # Wayland desktop
sudo apt install xclip         # X11 desktop

# Optional Rust language server
sudo apt install rustup
rustup toolchain install stable --profile minimal --component rust-analyzer
# Only if no default toolchain is configured
rustup default stable
# For an existing default toolchain, add its analyzer component
rustup component add rust-analyzer

# Optional Python language server in the user account
sudo apt install pipx
pipx install basedpyright==1.40.2
pipx ensurepath
```

```text
Language server paths
==========
Open a new login shell after pipx ensurepath, then reopen Neovim.
Language servers must be on PATH; existing zdotfiles-managed tools remain supported.
Missing language servers are disabled and do not block setup or verification.
```

## Linux setup

```bash
# ---------- bash ---------- #

# Neovim only: run as your normal user, including over SSH
./zdotfiles setup --only nvim --dry-run
make setup-nvim
./zdotfiles verify --only nvim

# Or choose one of these for the other editors
./zdotfiles setup
./zdotfiles setup --only vscode
```

```text
Neovim setup
==========
Uses installed programs; never invokes sudo, apt, pip, or rustup installation.
Missing required dependencies stop setup before config deployment.
Backs up changed config, downloads locked plugins, and builds parsers in user directories.
Network access is required for plugin/parser downloads.
Close and reopen Neovim after setup. In Normal mode, use \s to switch sidebar focus.
```

[Configuration](docs/configuration.md) · [Keyboard shortcuts](docs/keyboard-shortcuts.md)
