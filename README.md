# Rex Config

Personal [Rex](https://www.superlogical.com/rex) configuration with a single
`Ctrl+L` leader for everything, tmux-style controls, Vim navigation, and a
Gruvbox Dark Hard theme matching Ghostty and Neovim. Ported from my
[Herdr config](https://github.com/makyinmars/herdr-config).

## Configuration

Rex reads one Lua file:

```text
~/.config/rex/init.lua
```

The leader is `Ctrl+L`. Leader bindings are key sequences: press and release
`Ctrl+L`, then press the action key. `Esc` cancels a sequence. Press `Ctrl+L`
twice to send a literal `Ctrl+L` (clear screen) to the terminal.

Lowercase keys act on panes and tabs. Shift moves up a level to sessions and
windows.

Validate and reload without restarting Rex:

```bash
rex config check
rex config reload
```

Rex does not watch the file, so reload after every edit, from the terminal or
with `Ctrl+L r`. The full reference is at
[superlogical.com/rex/docs](https://www.superlogical.com/rex/docs/customize/config).

## Keybindings

`Leader` means `Ctrl+L`, released before the following key. Keys are written
unshifted in `init.lua`, so `%` is `shift+5` and `"` is `shift+'`.

### Panes

| Binding | Action |
| --- | --- |
| `Leader %` or `Leader \` | Split right |
| `Leader "` or `Leader -` | Split down |
| `Leader Space` | Split in the best-fitting direction |
| `Leader h/j/k/l` | Focus pane left/down/up/right |
| `Leader o` / `Leader Shift+O` | Focus next/previous pane |
| `Leader Shift+h/j/k/l` | Move pane left/down/up/right |
| `Leader z` | Toggle pane zoom |
| `Leader f` | Float the pane |
| `Leader =` | Balance splits |
| `Leader x` | Close the focused pane |
| `Leader Shift+B` | Move the pane to a new tab |
| `Leader Shift+M` | Move the pane to another tab (picker) |
| `Leader Shift+R` | Enter resize mode |

### Resize mode

| Binding | Action |
| --- | --- |
| `h/j/k/l` or arrows | Resize left/down/up/right |
| `Shift+h/j/k/l` or `Shift+arrows` | Resize in bigger steps |
| `=` | Balance splits |
| `Enter` or `Esc` | Leave resize mode |

Resize mode is exclusive: other keys are ignored while it is active, so
nothing is typed into the terminal by accident.

### Tabs

| Binding | Action |
| --- | --- |
| `Leader c` | Create a tab |
| `Leader n` / `Leader p` | Next/previous tab |
| `Leader 1` … `Leader 9` | Switch directly to a tab |
| `Leader ,` | Rename the current tab |
| `Leader {` / `Leader }` | Move the tab left/right |
| `Leader Shift+X` | Close the current tab |

### Sessions

Rex sessions correspond to Herdr workspaces.

| Binding | Action |
| --- | --- |
| `Leader s` | Open the session picker |
| `Leader Shift+C` | Create a session |
| `Leader Shift+N` / `Leader Shift+P` | Next/previous session |
| `Leader .` | Rename the current session |
| `Leader Shift+1` … `Leader Shift+9` | Switch directly to a session |
| `Leader Alt+5` | Switch to session 5 |

Numbered sessions follow the server's session order (new sessions are
appended); numbers with no session do nothing. Session 5 uses `Alt+5` because
`Shift+5` is `%`, the split key. Closing a session is left to the command
palette so it can't be hit by accident.

### App

| Binding | Action |
| --- | --- |
| `Leader :` | Open the command palette |
| `Leader Shift+S` | Open settings |
| `Leader Shift+W` | Open a new window |
| `Leader b` | Toggle the sidebar |
| `Leader a` | Toggle the activity panel |
| `Leader /` | Find in the terminal |
| `Leader [` / `Leader ]` | Jump to the previous/next prompt |
| `Leader d` | Go to a directory (picker) |
| `Leader i` | Insert a path (picker) |
| `Leader t` | Change theme (picker) |
| `Leader g` | Apply Gruvbox Dark Hard |
| `Leader +` / `Leader _` / `Leader )` | Font bigger/smaller/reset |
| `Leader r` | Reload the configuration |
| `Leader Ctrl+L` | Send `Ctrl+L` to the terminal |

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

Rex stores the selected theme in the app, not in Lua. On a new machine, press
`Ctrl+L g` once (or search **Apply Gruvbox Dark Hard** in the command palette)
to switch to dark mode and import the theme. Rex remembers it after that.

The font (Berkeley Mono Variable), font size, and density are also app
settings and live in Rex's Settings window, not in `init.lua`.

## Custom actions

`init.lua` defines two Lua actions, both available in the command palette:

- `session_by_index` (**Go to Numbered Session**) selects a session by its
  position in the server's session list.
- `apply_gruvbox_dark_hard` (**Apply Gruvbox Dark Hard**) switches to dark
  mode and imports the bundled theme file.

## Differences from Herdr

Splits, pane focus and swapping, zoom, closing panes and tabs, tab
navigation, the session picker, numbered sessions, settings, and the sidebar
use the same keys as Herdr. Rex has no equivalent for Herdr's file viewer
plugin, worktrees, agent cycling, Vim copy mode, scrollback editing, detach,
keybinding help, or last-pane toggle. These keys differ:

| Key | Herdr | Rex |
| --- | --- | --- |
| `Leader r` | Resize mode | Reload config |
| `Leader Shift+R` | Reload config | Resize mode |
| `Leader Shift+N` | New workspace | Next session (new is `Leader Shift+C`) |
| `Leader Shift+P` | Rename pane | Previous session |
| `Leader Shift+W` | Rename workspace | New window (rename is `Leader .`) |
| `Leader Shift+T` | Rename tab | Unbound (rename is `Leader ,`) |
| `Leader Shift+D` | Close workspace | Unbound (command palette) |
| `Leader Tab` / `Leader Shift+Tab` | Next/previous pane | Unbound (use `Leader o` / `Leader Shift+O`) |
| `Leader o` | Latest notification | Focus next pane |
| `Leader Shift+O` | Open worktree | Focus previous pane |
| `Leader g` | Session navigator | Apply Gruvbox Dark Hard |
| `Leader f` | File viewer | Float pane |
| `Leader [` | Copy mode | Jump to previous prompt |
| `Leader d` | Detach | Go to directory |
| `Leader .` / `Leader ,` | Next/previous agent | Rename session/tab |
| `Leader ;`, `Leader e`, `Leader ?`, `Leader Shift+F`, `Leader Shift+G` | Herdr-only features | Unbound |

## Installation

For a new machine:

```bash
git clone git@github.com:makyinmars/rex-config.git ~/.config/rex
rex config check
rex config reload
```

Then press `Ctrl+L g` once to apply the theme.

If `~/.config/rex` already exists, clone elsewhere and copy `init.lua` and
`themes/` into it. Set `REX_CONFIG` in the Rex server's environment to load
`init.lua` from another path.

## Requirements

- Rex Beta 0.1.0 (1541) or later on macOS
- Optional: [StyLua](https://github.com/JohnnyMorganz/StyLua) to check
  formatting with
  `stylua --check --indent-type Spaces --indent-width 2 init.lua`
