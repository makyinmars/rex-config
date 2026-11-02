-- Rex configuration: a Ctrl+L leader for everything, tmux-style controls, and
-- Vim navigation shared with Neovim. Appearance and fonts live in Rex.app
-- Settings, not here. README.md documents every key.
--
-- Custom actions live in actions/, shared helpers in lib/, and the background
-- event script in scripts/.

require("actions.view")
require("actions.sessions")
require("actions.panes")
require("actions.scrollback")
require("actions.agents")

-- Focus history and bell notifications need events, which only `rex do`
-- scripts receive. This keeps scripts/watch.lua running.
require("lib.watcher").ensure_running()

-- Ctrl+L is the leader: press and release it, then the action key. Escape
-- cancels a sequence.
local prefix = "ctrl+l>"

-- Panes. % and double quote must be spelled as unshifted keys plus Shift;
-- \ and - are easier-to-reach aliases for the same splits.
rex.bind(prefix .. "shift+5", "pane.split", { direction = "right" })
rex.bind(prefix .. "\\", "pane.split", { direction = "right" })
rex.bind(prefix .. "shift+'", "pane.split", { direction = "down" })
rex.bind(prefix .. "-", "pane.split", { direction = "down" })
rex.bind(prefix .. "space", "pane.split.auto")

-- h/j/k/l move between Neovim splits and Rex panes as one grid, wrapping at
-- the window's edges (actions/panes.lua).
rex.bind(prefix .. "h", "navigate", { direction = "left" })
rex.bind(prefix .. "j", "navigate", { direction = "down" })
rex.bind(prefix .. "k", "navigate", { direction = "up" })
rex.bind(prefix .. "l", "navigate", { direction = "right" })
rex.bind(prefix .. ";", "focus_last")
rex.bind(prefix .. "tab", "pane.focus_next")
rex.bind(prefix .. "shift+tab", "pane.focus_previous")

rex.bind(prefix .. "shift+h", "pane.move", { direction = "left" })
rex.bind(prefix .. "shift+j", "pane.move", { direction = "down" })
rex.bind(prefix .. "shift+k", "pane.move", { direction = "up" })
rex.bind(prefix .. "shift+l", "pane.move", { direction = "right" })

rex.bind(prefix .. "z", "pane.zoom")
rex.bind(prefix .. "x", "pane.close")
rex.bind(prefix .. "r", "client.mode.enter", { name = "resize" })
rex.bind(prefix .. "=", "pane.balance")
rex.bind(prefix .. "w", "pane.float")
rex.bind(prefix .. "shift+b", "pane.move_to_new_tab")
rex.bind(prefix .. "shift+m", "pane.move_to_tab")
rex.bind(prefix .. "y", "pane.copy_id")
rex.bind(prefix .. "shift+p", "rename_pane")
rex.bind(prefix .. "shift+f", "open_location")

-- Scrollback: copy mode, $EDITOR, the last command's output, and scroll mode.
rex.bind(prefix .. "[", "copy_mode")
rex.bind(prefix .. "e", "edit_scrollback")
rex.bind(prefix .. "shift+y", "copy_last_output")
rex.bind(prefix .. "shift+u", "client.mode.enter", { name = "scroll" })
rex.bind(prefix .. "pageup", "client.mode.enter", { name = "scroll" })

-- Agents, found by program status or process name, in every session.
rex.bind(prefix .. ".", "focus_agent", { step = 1 })
rex.bind(prefix .. ",", "focus_agent", { step = -1 })
rex.bind(prefix .. "o", "focus_attention")

-- Resize mode: h/j/k/l or arrows resize, Shift for bigger steps, = balances,
-- Enter or Escape leaves. Exclusive so stray keys never reach the terminal.
rex.mode("resize", { exclusive = true })
local resize_keys = {
  left = { "h", "left" },
  down = { "j", "down" },
  up = { "k", "up" },
  right = { "l", "right" },
}
for direction, keys in pairs(resize_keys) do
  for _, key in ipairs(keys) do
    rex.bind("resize/" .. key, "pane.resize", { direction = direction })
    rex.bind("resize/shift+" .. key, "pane.resize", { direction = direction, amount = 15 })
  end
end
rex.bind("resize/=", "pane.balance")
rex.bind("resize/enter", "client.mode.exit")

-- Scroll mode: k/j jump between shell prompts, or page through full-screen
-- programs. q, Enter, or Escape leaves.
rex.mode("scroll", { exclusive = true })
for _, key in ipairs({ "k", "up", "pageup" }) do
  rex.bind("scroll/" .. key, "scroll_step", { direction = "up" })
end
for _, key in ipairs({ "j", "down", "pagedown" }) do
  rex.bind("scroll/" .. key, "scroll_step", { direction = "down" })
end
rex.bind("scroll/q", "client.mode.exit")
rex.bind("scroll/enter", "client.mode.exit")

-- Tabs.
rex.bind(prefix .. "c", "client.tab.new")
rex.bind(prefix .. "n", "client.tab.next")
rex.bind(prefix .. "p", "client.tab.previous")
rex.bind(prefix .. "shift+t", "client.tab.rename")
rex.bind(prefix .. "shift+x", "client.tab.close")
rex.bind(prefix .. "shift+,", "client.tab.move.backward")
rex.bind(prefix .. "shift+.", "client.tab.move.forward")
rex.bind(prefix .. "shift+e", "client.tab.move_to_new_window")
rex.bind(prefix .. "shift+v", "open_neorex")
for index = 1, 9 do
  rex.bind(prefix .. index, "client.tab.goto", { index = index })
end

-- Sessions. f opens a project picker over sessions and zoxide's directories.
rex.bind(prefix .. "s", "session.switch")
rex.bind(prefix .. "g", "session.switch")
rex.bind(prefix .. "f", "project_picker")
rex.bind(prefix .. "shift+n", "session.new")
rex.bind(prefix .. "shift+w", "session.rename")
rex.bind(prefix .. "shift+d", "session.close")
rex.bind(prefix .. "shift+[", "session.previous")
rex.bind(prefix .. "shift+]", "session.next")
rex.bind(prefix .. "shift+z", "session.collapse_others")
rex.bind(prefix .. "u", "session.open_on_web")
-- Shift+5 is % (split right), so session 5 is Alt+5.
for index = 1, 9 do
  local modifier = index == 5 and "alt+" or "shift+"
  rex.bind(prefix .. modifier .. index, "session_by_index", { index = index })
end

-- App, search, and appearance, plus a way to send the original clear key.
rex.bind(prefix .. "b", "client.sidebar.toggle")
rex.bind(prefix .. "shift+s", "client.settings")
rex.bind(prefix .. "shift+r", "client.config.reload")
rex.bind(prefix .. "shift+/", "show_keys")
rex.bind(prefix .. "shift+;", "client.palette.toggle")
rex.bind(prefix .. "shift+c", "client.window.new")
rex.bind(prefix .. "a", "client.sidebar.activity.toggle")
rex.bind(prefix .. "/", "client.find.open")
rex.bind(prefix .. "up", "client.prompt.previous")
rex.bind(prefix .. "down", "client.prompt.next")
rex.bind(prefix .. "i", "pane.insert_path")
rex.bind(prefix .. "shift+i", "pane.go_to_directory")
rex.bind(prefix .. "t", "client.theme.change")
rex.bind(prefix .. "v", "client.tab_style.toggle")
rex.bind(prefix .. "shift+=", "client.font.increase")
rex.bind(prefix .. "shift+-", "client.font.decrease")
rex.bind(prefix .. "shift+0", "client.font.reset")
rex.bind(prefix .. "ctrl+l", "pane.send_key", { key = "ctrl+l" })

-- macOS shortcuts alongside the leader; Rex's other defaults remain.
-- Cmd+1-9 are left to Rex, which already goes to tabs with them: rebinding
-- them hides the tab number hints and loses the keypad digits.
rex.bind("cmd+t", "client.tab.new")
rex.bind("cmd+shift+n", "session.new")
rex.bind("cmd+alt+shift+n", "client.window.new")
rex.bind("cmd+d", "pane.split", { direction = "right" })
rex.bind("cmd+shift+d", "pane.split", { direction = "down" })
rex.bind("cmd+shift+]", "client.tab.next")
rex.bind("cmd+shift+[", "client.tab.previous")

rex.bind("cmd+alt+left", "navigate", { direction = "left" })
rex.bind("cmd+alt+down", "navigate", { direction = "down" })
rex.bind("cmd+alt+up", "navigate", { direction = "up" })
rex.bind("cmd+alt+right", "navigate", { direction = "right" })
rex.bind("cmd+alt+]", "pane.focus_next")
rex.bind("cmd+alt+[", "pane.focus_previous")
rex.bind("cmd+shift+enter", "pane.zoom")
rex.bind("cmd+ctrl+f", "client.window.fullscreen.toggle")
rex.bind("cmd+w", "pane.close")
rex.bind("cmd+shift+w", "client.tab.close")

rex.bind("cmd+b", "client.sidebar.toggle")
rex.bind("cmd+=", "client.font.increase")
rex.bind("cmd+shift+=", "client.font.increase")
rex.bind("cmd+-", "client.font.decrease")
rex.bind("cmd+0", "client.font.reset")
rex.bind("cmd+,", "client.settings")
rex.bind("cmd+p", "session.switch")
rex.bind("cmd+shift+p", "client.palette.toggle")

-- Native terminal search. For keyboard copying, Leader [ opens copy mode.
-- Cmd+Shift+G is left to Rex: previous match while the find bar is open, Go
-- to Directory otherwise.
rex.bind("cmd+f", "client.find.open")
rex.bind("cmd+g", "client.find.next")
