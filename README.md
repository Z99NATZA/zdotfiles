# zdotfiles

## Setup

```bash
# ---------- bash ---------- #

# Neovim, VS Code, GNOME
make setup-all
./zdotfiles verify

# Neovim
./zdotfiles setup --only nvim --dry-run
make setup-nvim
./zdotfiles verify --only nvim

# VS Code
make setup-vscode
./zdotfiles verify --only vscode

# GNOME settings and custom extensions
./zdotfiles setup --only gnome --dry-run
make setup-gnome
./zdotfiles verify --only gnome
```

## Neovim inlay hints

```bash
# ---------- bash ---------- #

# Config updates automatically; reopen Neovim after changing hints

# Rust
make enable-hint-rust
make disable-hint-rust

# Python
make enable-hint-py
make disable-hint-py
```

[Configuration](docs/configuration.md)

[Required packages](docs/configuration.md#ubuntu-packages)

[Keyboard shortcuts](docs/keyboard-shortcuts.md)
