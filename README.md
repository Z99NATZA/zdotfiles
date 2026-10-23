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

[Configuration](docs/configuration.md)

[Required packages](docs/configuration.md#ubuntu-packages)

[Keyboard shortcuts](docs/keyboard-shortcuts.md)
