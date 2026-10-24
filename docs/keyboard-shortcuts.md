# Keyboard Shortcuts

## GNOME

| Shortcut | Action |
|---|---|
| `Super+N` / `Super+M` | Switch to the workspace on the left / right |
| `Super+O` | Open or close Overview in window-selection mode |
| `J` / `K` in Overview | Select the next / previous window |
| Arrow keys in Overview | Select a window in that direction |
| `I` in Overview | Focus search |
| `Enter` in Overview | Open the selected window; in search, open a new app window when supported |
| `Escape` in Overview | Close Overview |
| `Print` / `Super+Shift+S` | Open the screenshot UI |
| `Ctrl+Shift` | Switch between English and Thai input |

```text
Desktop profile
==========
Super alone does not open Overview. Super+H, Super+L, and Super+Left/Right
are freed from their GNOME minimize, lock, and tiling actions for editor use.
Super+M is freed from the notification tray; Super+V still opens the tray.
Super+N is freed from notification focus. The old workspace Super+B binding
on the left and Super+N binding on the right are removed.
Overview J/K/I use physical keys, so they also work with the Thai layout active.
Custom Overview behavior requires Super O Search on GNOME Shell 50.
Search launches the selected app result, or the first app when none is selected.
Apps with a new-window desktop action, or running apps that support new windows,
open a new window. For zter, its new-window action runs zter --standalone.
Other apps use their normal activation behavior. zter's launcher is installed
by zter itself; zdotfiles does not install or rewrite application launchers.
```

## VS Code

| Shortcut | Action |
|---|---|
| `Alt+K` / `Alt+J` | Move the current line up or down |
| `Ctrl+0` | Switch focus between the editor and primary sidebar |
| `Ctrl+B` | Toggle the primary sidebar |
| `Super+-` / `Super+=` | Shrink or expand the focused editor group; adjust terminal height when the terminal is focused |
| `Super+,` / `Super+.` | Shrink or expand the primary sidebar |
| `Super+H` / `Super+L` | Open the previous or next editor tab in the group |
| `Super+J` / `Super+K` | Focus the terminal (create one if needed) or return to the active editor group |
| `Super+W` | Close the focused editor tab |
| `Ctrl+D` in VSCodeVim Visual mode | Add the next matching selection |

```text
Notes
==========
Super is meta in VS Code keybindings.
Sidebar resizing restores the previous focus; repeated operations are serialized.
```

## VSCodeVim

| Shortcut | Action |
|---|---|
| `kj` in Insert mode | Return to Normal mode |
| `Ctrl+J` / `Ctrl+K` | Move down or up five lines in Normal and Visual modes |
| `K` in Normal mode | Show editor hover information |
| `Ctrl+P` in Normal mode | Open Quick Open |
| `y` | Yank to the system clipboard |

```text
Copy
==========
Ctrl+C and Ctrl+Insert native copy bindings are removed in text inputs.
Terminal copy shortcuts are unchanged.

Multiple selections
----------
v + motion  Select text
Ctrl+D      Add the next matching selection
c           Replace every selection and enter Insert mode
Esc         Leave Insert mode
Esc         Return to a single cursor

Outside Visual mode, Ctrl+D keeps Vim half-page scrolling.
```

## Neovim

| Shortcut | Action |
|---|---|
| `kj` in Insert mode | Return to Normal mode |
| `Ctrl+J` / `Ctrl+K` | Move five lines down or up in Normal and Visual modes |
| `Alt+J` / `Alt+K` | Move the line or selection down or up |
| `Ctrl+0` | Switch focus between the nvim-tree sidebar and editor |
| `\s` in Normal mode | Switch focus between the nvim-tree sidebar and editor |
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

```text
Mappings
==========
Source: .config/nvim/init.lua. Leader: \

Sidebar focus
----------
Ctrl+0 works in Normal, Insert, Visual, and Terminal modes.
\s provides the same action in Normal mode, including over SSH.
Opens/focuses the sidebar, then returns to the previous editor split.
If that split closed, selects another editor in the tab or creates one.

Terminal support
----------
The host must forward Ctrl+0 distinctly, e.g. CSI-u ESC [ 48 ; 5 u.
zter forwards top-row zero across US/Thai Kedmanee layouts unless a shortcut consumes it.
Super mappings also require host-terminal forwarding.
```
