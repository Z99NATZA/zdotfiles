# zdotfiles

## Setup

Install the [required packages](docs/configuration.md#ubuntu-packages) first,
then run the commands for the editor you want.

```bash
# ---------- bash ---------- #

# Preview, set up, and verify Neovim
./zdotfiles setup --only nvim --dry-run
make setup-nvim
./zdotfiles verify --only nvim

# Set up both Neovim and VS Code
make setup-all
./zdotfiles verify

# Set up VS Code only
make setup-vscode
./zdotfiles verify --only vscode
```

[Configuration](docs/configuration.md) covers setup options and
[keyboard shortcuts](docs/keyboard-shortcuts.md) after installation.
