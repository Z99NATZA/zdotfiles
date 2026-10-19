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
