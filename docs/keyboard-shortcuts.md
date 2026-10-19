# Keyboard Shortcuts

`Super` is represented as `meta` in VS Code's keybindings file.

## VS Code

| Shortcut | Action |
| --- | --- |
| `Alt+K` / `Alt+J` | Move the current line up or down |
| `Ctrl+0` | Switch focus between the editor and primary sidebar |
| `Ctrl+B` | Toggle the primary sidebar |
| `Super+-` / `Super+=` | Shrink or expand the focused editor group; adjust terminal height when the terminal is focused |
| `Super+,` / `Super+.` | Shrink or expand the primary sidebar |
| `Super+H` / `Super+L` | Open the previous or next editor tab in the group |
| `Super+J` / `Super+K` | Focus the terminal (create one if needed) or return to the active editor group |
| `Super+W` | Close the focused editor tab |
| `Ctrl+D` in VSCodeVim Visual mode | Add the next matching selection |

Sidebar resizing temporarily focuses the sidebar, performs one resize, and
restores the previous editor, terminal, panel, or auxiliary-bar focus. The
local extension prevents overlapping key-repeat operations from resizing the
wrong editor group.

## VSCodeVim

| Shortcut | Action |
| --- | --- |
| `kj` in Insert mode | Return to Normal mode |
| `Ctrl+J` / `Ctrl+K` | Move down or up five lines in Normal and Visual modes |
| `K` in Normal mode | Show editor hover information |
| `Ctrl+P` in Normal mode | Open Quick Open |
| `y` | Yank to the system clipboard |

Native editor copy bindings for `Ctrl+C` and `Ctrl+Insert` are removed while a
text input has focus. Terminal copy shortcuts are unaffected.

### Multiple Selections

Select text in Visual mode, then press `Ctrl+D` repeatedly to add matching
selections using VS Code's default `editor.action.addSelectionToNextFindMatch`
command.

```text
v + motion  Select text
Ctrl+D      Add the next matching selection
c           Replace every selection and enter Insert mode
Esc         Leave Insert mode
Esc         Return to a single cursor
```

`Ctrl+D` retains its normal Vim half-page scrolling behavior outside Visual
mode.

## Neovim

The leader key is `\`. These are custom mappings in `.config/nvim/init.lua`:

| Shortcut | Action |
| --- | --- |
| `kj` in Insert mode | Return to Normal mode |
| `Ctrl+J` / `Ctrl+K` | Move five lines down or up in Normal and Visual modes |
| `Alt+J` / `Alt+K` | Move the line or selection down or up |
| `Ctrl+B` | Toggle nvim-tree sidebar |
| `Ctrl+Space` | Toggle the terminal panel |
| `Super+,` / `Super+.` | Shrink or expand the visible sidebar |
| `Super+-` / `Super+=` | Shrink or expand the visible terminal panel |
| `\e` / `\ff` | Open a file path or find files with Telescope |
| `\cp` | Copy the selected file path or current file path |
| `\w` / `\df` | Save the file or save all files and quit |
| `\rs` | Restart Neovim and reload the configuration |
| `K` / `gd` / `gr` | Show a hint, go to a definition, or find references (LSP) |
| `[h` / `]h` | Go to the previous or next Git change |

Neovim receives `Super` shortcuts only when the host terminal forwards them.
