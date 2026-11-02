# Rex Config

Personal [Rex](https://www.superlogical.com/rex) configuration: a single
`Ctrl+L` leader for everything, tmux-style controls, one Vim-style grid for
Rex panes and Neovim splits, keyboard copy mode, a project picker, and a
Gruvbox Dark Hard theme matching Ghostty and Neovim. It pairs with the Rex
integration in `~/.config/nvim/lua/rex`.

## Configuration

Rex reads `~/.config/rex/init.lua`, which loads the rest:

```text
init.lua              key bindings and modes; loads everything below
actions/              custom actions, by area
  sessions.lua        numbered sessions, project picker
  panes.lua           rename, navigate, last pane, open file locations
  scrollback.lua      copy mode, edit scrollback, copy last output, scroll mode
  agents.lua          agent navigation and the agent list Neovim uses
  view.lua            theme import, keybinding help
lib/common.lua        helpers shared by the actions
lib/watcher.lua       keeps scripts/watch.lua running
scripts/watch.sh      supervisor for watch.lua, survives server restarts
scripts/watch.lua     event script: focus history and bell notifications
scripts/open-location.lua  opens a picked file:line in Neovim
nvim/copy-mode.lua    the bare Neovim copy mode runs
shell/rex.zsh         zsh integration and the rex_status/track helpers
types/rex.lua         LuaCATS types for the rex API (editor only)
themes/               Gruvbox Dark Hard, copied from Ghostty
```

The leader is `Ctrl+L`. Leader bindings are key sequences: press and release
`Ctrl+L`, then press the action key. `Esc` cancels a sequence. Press `Ctrl+L`
twice to send a literal `Ctrl+L` (clear screen) to the terminal.

Validate and reload without restarting Rex:

```bash
rex config check
rex config reload
```

Rex does not watch the files, so reload after every edit, from the terminal or
with `Ctrl+L Shift+R`. The full reference is at
[superlogical.com/rex/docs](https://www.superlogical.com/rex/docs/customize/config).

`rex config check` only sees the files. `rex keymap` asks the running server
what it loaded, with the line behind each binding, and is where a misspelled
action name or a sequence that hides another binding shows up. To try an
action without reloading:

```bash
rex do ~/.config/rex/init.lua --action copy_mode
```

## Keybindings

`Leader` means `Ctrl+L`, released before the following key. Keys are written
unshifted in `init.lua`, so `%` is `shift+5` and `"` is `shift+'`.

### Sessions

| Binding | Action |
| --- | --- |
| `Leader f` | Project picker: running sessions and zoxide directories |
| `Leader s` / `Leader g` | Open the session picker |
| `Leader Shift+1` … `Leader Shift+9` | Switch directly to a session |
| `Leader Alt+5` | Switch to session 5 |
| `Leader Shift+N` | Create a session |
| `Leader Shift+W` | Rename the current session |
| `Leader Shift+D` | Close the current session |
| `Leader {` / `Leader }` | Previous/next session |
| `Leader Shift+Z` | Collapse every other session in the sidebar |
| `Leader u` | Open the session on the web, over Tailscale |

In the project picker, a session switches to it. A directory switches to the
session with the directory's name, or creates one with Neovim on the left
(65%) and a shell on the right. Neovim is typed into a shell, so quitting it
leaves the shell.

Numbered sessions follow the server's session order (new sessions are
appended); numbers with no session do nothing. Session 5 uses `Alt+5` because
`Shift+5` is `%`, the split key.

### Tabs

| Binding | Action |
| --- | --- |
| `Leader c` | Create a tab |
| `Leader Shift+T` | Rename the current tab |
| `Leader n` / `Leader p` | Next/previous tab |
| `Leader 1` … `Leader 9` | Switch directly to a tab |
| `Leader Shift+X` | Close the current tab |
| `Leader <` / `Leader >` | Move the tab left/right |
| `Leader Shift+E` | Move the tab to a new window |
| `Leader Shift+V` | Open Neovim through neorex in a new tab, in the pane's directory |

`Leader Shift+V` runs [neorex](https://github.com/alexrlocke/neorex), which
shows each Neovim window as its own Rex pane. It starts through an
interactive zsh, so Neovim gets the same `PATH` as typing `neorex` at the
prompt. The tab closes when Neovim quits.

### Panes

| Binding | Action |
| --- | --- |
| `Leader h/j/k/l` | Focus left/down/up/right across panes and Neovim splits, wrapping at the edges |
| `Leader ;` | Go back to the pane this tab had focused before (tmux's last-pane) |
| `Leader Shift+h/j/k/l` | Move pane left/down/up/right |
| `Leader %` / `Leader \` | Split right |
| `Leader "` / `Leader -` | Split down |
| `Leader Space` | Split in the best-fitting direction |
| `Leader x` | Close the focused pane |
| `Leader z` | Toggle pane zoom |
| `Leader Tab` / `Leader Shift+Tab` | Focus next/previous pane |
| `Leader r` | Enter resize mode |
| `Leader =` | Balance splits |
| `Leader w` | Float the pane |
| `Leader Shift+B` | Move the pane to a new tab |
| `Leader Shift+M` | Move the pane to another tab, with a picker |
| `Leader Shift+P` | Rename the focused pane |
| `Leader y` | Copy the pane's ID, for `rex -b` |
| `Leader Shift+F` | Open a file location printed in the pane, in Neovim |

`Leader Shift+F` lists the `path:line`, `path:line:col`, `path(line,col)`, and
`@path#L12` locations in the pane, plus bare file names, that exist on disk,
newest first, with a `bat` preview. The pick opens in the Neovim running in
this tab, through its socket, or in a new Neovim split.

### Scrollback

| Binding | Action |
| --- | --- |
| `Leader [` | Copy mode |
| `Leader e` | Edit the pane's scrollback in `$EDITOR` |
| `Leader Shift+Y` | Copy the last command's output |
| `Leader Shift+U` / `Leader Page Up` | Enter scroll mode |
| `Leader /` | Find in the terminal |
| `Leader Up` / `Leader Down` | Jump to the previous/next prompt |

Copy mode opens the pane's scrollback in a bare Neovim
(`nvim/copy-mode.lua`, no plugins) at the bottom. `v`, move, then `y` or
`Enter` copies to the clipboard and closes; any yank (`yy`, `yiw`) does the
same. `/` searches, `q` closes. Full-screen programs (Neovim, lazygit) have no
scrollback, so for those it shows what is on screen.

`Leader Shift+Y` finds commands by the Starship prompt (`╭─` then `╰─❯`). If
the prompt changes, update `prompt_header` and `prompt_line` in
`actions/scrollback.lua`. Running it through `rex do copy_last_output
command=true` includes the command.

### Scroll mode

| Binding | Action |
| --- | --- |
| `k` / `Up` / `Page Up` | Previous prompt, or page up in a full-screen program |
| `j` / `Down` / `Page Down` | Next prompt, or page down in a full-screen program |
| `q`, `Enter`, or `Esc` | Leave scroll mode |

### Agents

| Binding | Action |
| --- | --- |
| `Leader .` / `Leader ,` | Focus the next/previous agent, in any session |
| `Leader o` | Go to the pane that most recently finished, failed, or got blocked |

A pane counts as an agent when its program reports a known app through
Rex's [Program Status Protocol](https://www.superlogical.com/rex/docs/build/program-status)
(Claude Code does), or when its foreground process is `claude`, `codex`,
`opencode`, `pi`, `gemini`, `grok`, `aider`, or `amp`. `Leader o` works for
any program that reports status, including commands run with `track`. Both
say so when there is nowhere to go.

### Resize mode

| Binding | Action |
| --- | --- |
| `h/l` or `Left/Right` | Resize width |
| `j/k` or `Down/Up` | Resize height |
| `Shift` + any of the above | Resize in bigger steps |
| `=` | Balance splits |
| `Enter` or `Esc` | Leave resize mode |

Resize and scroll modes are exclusive: other keys are ignored while they are
active, so nothing is typed into the terminal by accident.

### Rex controls

| Binding | Action |
| --- | --- |
| `Leader b` | Toggle the sidebar |
| `Leader Shift+S` | Open settings |
| `Leader Shift+R` | Reload the configuration |
| `Leader ?` | Show this README's keybindings in a floating pager |
| `Leader :` | Open the command palette |
| `Leader Shift+C` | Open a new window |
| `Leader a` | Toggle the activity panel |
| `Leader i` | Insert a path, with a picker |
| `Leader Shift+I` | Go to a directory, with a picker |
| `Leader t` | Change theme, with a picker |
| `Leader v` | Toggle the tab style |
| `Leader +` / `Leader _` / `Leader )` | Font bigger/smaller/reset |
| `Leader Ctrl+L` | Send `Ctrl+L` to the terminal |

### macOS shortcuts

| Binding | Action |
| --- | --- |
| `Cmd+D` / `Cmd+Shift+D` | Split right/down |
| `Cmd+Alt+arrows` | Focus across panes and Neovim splits, wrapping at the edges |
| `Cmd+Alt+[` / `Cmd+Alt+]` | Focus previous/next pane |
| `Cmd+Shift+Enter` | Toggle pane zoom |
| `Cmd+Ctrl+F` | Toggle full screen |
| `Cmd+W` / `Cmd+Shift+W` | Close pane/tab |
| `Cmd+T` | New tab |
| `Cmd+1` … `Cmd+9` | Switch directly to a tab |
| `Cmd+Shift+[` / `Cmd+Shift+]` | Previous/next tab |
| `Cmd+Shift+N` | New session |
| `Cmd+Alt+Shift+N` | New window |
| `Cmd+P` | Session picker |
| `Cmd+Shift+P` | Command palette |
| `Cmd+B` | Toggle the sidebar |
| `Cmd+F`, `Cmd+G` | Find, find next |
| `Cmd+Shift+G` | Previous match while finding, otherwise Go to Directory (Rex default) |
| `Cmd+=` / `Cmd+-` / `Cmd+0` | Font bigger/smaller/reset |
| `Cmd+,` | Settings |

`Cmd+1` … `Cmd+9` and `Cmd+Shift+G` are Rex's own defaults and are
deliberately not rebound: binding `Cmd+1` … `Cmd+9` hides the tab number hints
and stops the keypad digits from working, and Rex's `Cmd+Shift+G` switches
between find and Go to Directory on its own.

A shortcut changed inside the app with **Change Shortcut…** overrides
`init.lua`. If a binding seems to do nothing, check the app first.

## Neovim integration

`~/.config/nvim/lua/rex` (set up from `lua/config/autocmds.lua`) is the other
half of several features. It does nothing outside Rex or under neorex.

- **Status.** Neovim reports itself with OSC 7501 (`id=nvim`, `app=nvim`):
  idle with the current file, working while a language server reports
  progress. Activity shows it with idle processes on.
- **Navigation.** In a pane whose Neovim reports `app=nvim`, the `navigate`
  action sends F13–F16 instead of moving focus. Neovim moves between its
  splits and, at the edge, runs `rex focus DIRECTION --wrap`. Other Neovims
  (copy mode, `nvim --clean`) get normal pane focus.
- **Opening files.** Each Neovim listens on
  `$TMPDIR/nvim-rex-<last 12 of the block ID>.sock`, which `Leader Shift+F`
  opens files through.
- **Sending to agents.** `<leader>a` in Neovim pastes context into an agent
  pane, without submitting:

| Neovim key | Sends |
| --- | --- |
| `<leader>ay` | `@path#L12` (or `#L12-L20` for a selection) |
| `<leader>aY` | The reference and the code |
| `<leader>ap` | The reference (and selection), plus a question you type |
| `<leader>ad` | Diagnostics for the buffer, or the selection |
| `<leader>as` | The function or class around the cursor |
| `<leader>ah` | The git hunk under the cursor |
| `<leader>aq` / `<leader>al` | The quickfix / location list |
| `<leader>at` | Pick the agent to send to |
| `<leader>aa` | Go to the agent's pane |

With one agent in the session it is used directly; otherwise Neovim asks, and
remembers the pick until `<leader>at`. The list comes from the `agent_panes`
action (`rex do agent_panes --json`), this session's agents first.

## Background watcher

The configuration file never receives events, so `scripts/watch.lua` runs as
`rex do --all` and:

- records each tab's focused pane and the one before it in
  `~/.local/state/rex-config/focus.json`, for `Leader ;`;
- turns a bell from a pane you aren't in into a macOS notification, at most
  one per pane every 30 seconds, skipping panes whose programs report status
  (Rex already notifies for those).

`lib/watcher.lua` starts `scripts/watch.sh` whenever the configuration loads,
unless it is already running. The supervisor waits for the server, restarts
the script after server restarts, and never starts a server itself. Its log
is `~/.local/state/rex-config/watch.log`. To stop it until the next reload:

```bash
kill "$(cat ~/.local/state/rex-config/watch.pid)"
```

After editing `scripts/watch.lua`, restart it with
`pkill -f 'do --all .*watch.lua'`; the supervisor starts the new version.

## Shell integration

`shell/rex.zsh` makes zsh tell Rex where prompts and commands begin (OSC 133)
and which directory it is in (OSC 7). Starship emits neither, and without
them:

- `Leader Up` / `Leader Down` and scroll mode have no prompts to jump between.
- A program that crashes while *working* or *blocked* keeps its spinner,
  because Rex clears those states when the shell's prompt returns.
- Lua's `terminal.pwd_changed` event and the terminal's `pwd` stay empty.

It also puts the `rex` that matches the server back at the front of `PATH`,
as the [CLI docs](https://www.superlogical.com/rex/docs/automate/cli#path)
recommend, and adds two helpers:

```zsh
track bun test              # working while it runs, then done or error
rex_status working "Deploying"
rex_status done "Deployed"  # stays until you look at the pane
```

`~/.zshrc` sources it just before zoxide's init, which must stay last:

```zsh
[[ -n $REX_SESSION && -r ~/.config/rex/shell/rex.zsh ]] && source ~/.config/rex/shell/rex.zsh
```

It does nothing outside Rex, and its prompt hook runs first and hands the exit
status on, so Starship and Atuin still see it.

## Custom actions

All are in the command palette, and `rex do NAME` runs them from a shell.

- `navigate` (**Focus Pane or Neovim Split**), `focus_last` (**Focus Last
  Pane**), `rename_pane`, `open_location` (**Open File Location in Neovim…**)
- `copy_mode`, `edit_scrollback`, `copy_last_output`, `scroll_step`
- `project_picker` (**Open Project…**), `open_project` (`kind=dir
  value=PATH`, or `kind=session value=ID`; `select=false` skips switching),
  `session_by_index`, `open_neorex` (**Open Neovim in a New Tab**)
- `focus_agent`, `focus_attention`, `agent_panes`, `focus_pane`
- `apply_gruvbox_dark_hard`, `show_keys`

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

## Editing this config

`.luarc.json` points lua-language-server at Lua 5.1 and `types/rex.lua`, so
`rex.*` gets completion and signature help. Rex doesn't ship these types yet;
they follow the [Lua API reference](https://www.superlogical.com/rex/docs/reference/lua).
`stylua.toml` holds the formatting (2 spaces, 120 columns):

```bash
stylua --check .
```

## Installation

For a new machine:

```bash
git clone git@github.com:makyinmars/rex-config.git ~/.config/rex
rex config check
rex config reload
```

Then run **Apply Gruvbox Dark Hard** from the command palette once, and add
the [shell integration](#shell-integration) line to `~/.zshrc`.

If `~/.config/rex` already exists, clone elsewhere and copy the files into it.
Set `REX_CONFIG` in the Rex server's environment to load `init.lua` from
another path.

## Requirements

- Rex Beta 0.1.0 (1642) or later on macOS
- Neovim 0.12 or later with `~/.config/nvim/lua/rex`, for navigation, opening
  locations, and sending to agents
- [fzf](https://github.com/junegunn/fzf) for `Leader f` and `Leader Shift+F`,
  [zoxide](https://github.com/ajeetdsouza/zoxide) for directories in
  `Leader f`, and optionally [bat](https://github.com/sharkdp/bat) for the
  location preview
- Optional: [glow](https://github.com/charmbracelet/glow) for `Leader ?`
- Optional: [neorex](https://github.com/alexrlocke/neorex) on the `PATH`
  `~/.zshrc` sets, for `Leader Shift+V`
- Optional: [StyLua](https://github.com/JohnnyMorganz/StyLua) and
  lua-language-server for editing
