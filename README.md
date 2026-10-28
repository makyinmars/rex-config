# Rex Config

Personal [Rex](https://www.superlogical.com/rex) configuration with a single
`Ctrl+L` leader for everything, tmux-style controls, Vim navigation, and a
Gruvbox Dark Hard theme matching Ghostty and Neovim. The keys follow my
[Herdr config](https://github.com/makyinmars/herdr-config), so the same muscle
memory works in both.

## Configuration

Rex reads one Lua file:

```text
~/.config/rex/init.lua
```

The leader is `Ctrl+L`. Leader bindings are key sequences: press and release
`Ctrl+L`, then press the action key. `Esc` cancels a sequence. Press `Ctrl+L`
twice to send a literal `Ctrl+L` (clear screen) to the terminal.

Validate and reload without restarting Rex:

```bash
rex config check
rex config reload
```

Rex does not watch the file, so reload after every edit, from the terminal or
with `Ctrl+L Shift+R`. The full reference is at
[superlogical.com/rex/docs](https://www.superlogical.com/rex/docs/customize/config).

## Keybindings

`Leader` means `Ctrl+L`, released before the following key. Every key that
exists in Herdr does the same thing here; bindings marked *Rex* are extras on
keys Herdr leaves free. Keys are written unshifted in `init.lua`, so `%` is
`shift+5` and `"` is `shift+'`.

### Sessions

Rex sessions correspond to Herdr workspaces.

| Binding | Action |
| --- | --- |
| `Leader s` | Open the session picker |
| `Leader g` | Open the session picker (Herdr's session navigator) |
| `Leader Shift+1` … `Leader Shift+9` | Switch directly to a session |
| `Leader Alt+5` | Switch to session 5 |
| `Leader Shift+N` | Create a session |
| `Leader Shift+W` | Rename the current session |
| `Leader Shift+D` | Close the current session |
| `Leader {` / `Leader }` | Previous/next session (*Rex*) |

Numbered sessions follow the server's session order (new sessions are
appended); numbers with no session do nothing. Session 5 uses `Alt+5` because
`Shift+5` is `%`, the split key. Herdr has the same conflict.

### Tabs

| Binding | Action |
| --- | --- |
| `Leader c` | Create a tab |
| `Leader Shift+T` | Rename the current tab |
| `Leader n` / `Leader p` | Next/previous tab |
| `Leader 1` … `Leader 9` | Switch directly to a tab |
| `Leader Shift+X` | Close the current tab |
| `Leader <` / `Leader >` | Move the tab left/right (*Rex*) |

### Panes

| Binding | Action |
| --- | --- |
| `Leader h/j/k/l` | Focus pane left/down/up/right |
| `Leader Shift+h/j/k/l` | Move pane left/down/up/right |
| `Leader %` | Split right |
| `Leader "` | Split down |
| `Leader x` | Close the focused pane |
| `Leader z` | Toggle pane zoom |
| `Leader Tab` / `Leader Shift+Tab` | Focus next/previous pane |
| `Leader r` | Enter resize mode |
| `Leader \` / `Leader -` | Split right/down (*Rex*) |
| `Leader Space` | Split in the best-fitting direction (*Rex*) |
| `Leader =` | Balance splits (*Rex*) |
| `Leader w` | Float the pane (*Rex*) |
| `Leader Shift+B` | Move the pane to a new tab (*Rex*) |
| `Leader Shift+M` | Move the pane to another tab, with a picker (*Rex*) |

### Resize mode

| Binding | Action |
| --- | --- |
| `h/l` or `Left/Right` | Resize width |
| `j/k` or `Down/Up` | Resize height |
| `Shift` + any of the above | Resize in bigger steps |
| `=` | Balance splits |
| `Enter` or `Esc` | Leave resize mode |

Resize mode is exclusive: other keys are ignored while it is active, so
nothing is typed into the terminal by accident.

### Rex controls

| Binding | Action |
| --- | --- |
| `Leader b` | Toggle the sidebar |
| `Leader Shift+S` | Open settings |
| `Leader Shift+R` | Reload the configuration |
| `Leader :` | Open the command palette (*Rex*) |
| `Leader Shift+C` | Open a new window (*Rex*) |
| `Leader a` | Toggle the activity panel (*Rex*) |
| `Leader /` | Find in the terminal (*Rex*) |
| `Leader Up` / `Leader Down` | Jump to the previous/next prompt (*Rex*) |
| `Leader i` | Insert a path, with a picker (*Rex*) |
| `Leader Shift+I` | Go to a directory, with a picker (*Rex*) |
| `Leader t` | Change theme, with a picker (*Rex*) |
| `Leader +` / `Leader _` / `Leader )` | Font bigger/smaller/reset (*Rex*) |
| `Leader Ctrl+L` | Send `Ctrl+L` to the terminal |

### Not available in Rex

Rex has no equivalent for these Herdr features, so their keys are left
unbound rather than given unrelated meanings:

| Binding | Herdr action |
| --- | --- |
| `Leader ;` | Jump to the last pane |
| `Leader Shift+P` | Rename the focused pane |
| `Leader f` / `Leader Shift+F` | Open the file viewer |
| `Leader Shift+G` / `Leader Shift+O` | Create/open a Git worktree |
| `Leader .` / `Leader ,` | Focus the next/previous agent |
| `Leader o` | Open the latest notification target |
| `Leader d` | Detach |
| `Leader ?` | Show keybinding help |
| `Leader e` | Edit pane scrollback |
| `Leader [` | Enter copy mode (`Leader /` searches instead) |

### macOS shortcuts

Herdr's native Cmd shortcuts work alongside the leader:

| Binding | Action |
| --- | --- |
| `Cmd+D` / `Cmd+Shift+D` | Split right/down |
| `Cmd+Alt+arrows` | Focus pane |
| `Cmd+Alt+[` / `Cmd+Alt+]` | Focus previous/next pane |
| `Cmd+Shift+Enter` | Toggle pane zoom |
| `Cmd+W` / `Cmd+Shift+W` | Close pane/tab |
| `Cmd+T` | New tab |
| `Cmd+1` … `Cmd+9` | Switch directly to a tab |
| `Cmd+Shift+[` / `Cmd+Shift+]` | Previous/next tab |
| `Cmd+Shift+N` | New session |
| `Cmd+Alt+Shift+N` | New window |
| `Cmd+P` | Session picker |
| `Cmd+Shift+P` | Command palette |
| `Cmd+B` | Toggle the sidebar |
| `Cmd+F`, `Cmd+G`, `Cmd+Shift+G` | Find, next, previous |
| `Cmd+=` / `Cmd+-` / `Cmd+0` | Font bigger/smaller/reset |
| `Cmd+,` | Settings |

A shortcut changed inside the app with **Change Shortcut…** overrides
`init.lua`. If a binding seems to do nothing, check the app first.

## Theme

`themes/Gruvbox Dark Hard` is copied verbatim from Ghostty's bundled theme:

- Background: `#1d2021`
- Foreground: `#ebdbb2`
- Selection: `#665c54`
- Red: `#fb4934`
- Green: `#b8bb26`
- Yellow: `#fabd2f`
- Blue: `#83a598`
- Purple: `#d3869b`
- Aqua: `#8ec07c`

Rex stores the selected theme in the app, not in Lua. On a new machine, open
the command palette (`Ctrl+L :`) and run **Apply Gruvbox Dark Hard** once. It
switches to dark mode and imports the theme, and Rex remembers it after that.

The font (Berkeley Mono Variable), font size, and density are also app
settings and live in Rex's Settings window, not in `init.lua`.

## Custom actions

`init.lua` defines two Lua actions, both available in the command palette:

- `session_by_index` (**Go to Numbered Session**) selects a session by its
  position in the server's session list.
- `apply_gruvbox_dark_hard` (**Apply Gruvbox Dark Hard**) switches to dark
  mode and imports the bundled theme file.

## Installation

For a new machine:

```bash
git clone git@github.com:makyinmars/rex-config.git ~/.config/rex
rex config check
rex config reload
```

Then run **Apply Gruvbox Dark Hard** from the command palette once.

If `~/.config/rex` already exists, clone elsewhere and copy `init.lua` and
`themes/` into it. Set `REX_CONFIG` in the Rex server's environment to load
`init.lua` from another path.

## Requirements

- Rex Beta 0.1.0 (1541) or later on macOS
- Optional: [StyLua](https://github.com/JohnnyMorganz/StyLua) to check
  formatting with
  `stylua --check --indent-type Spaces --indent-width 2 init.lua`
