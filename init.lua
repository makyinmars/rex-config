-- Herdr-style shortcuts. Appearance and fonts live in Rex.app Settings,
-- not in the Lua configuration. See README.md for the theme and migration notes.

-- Herdr workspaces correspond to Rex sessions. Preserve numbered switching
-- using the server's session order (new sessions are appended).
rex.action({
  name = "session_by_index",
  title = "Go to Numbered Session",
  category = "Session",
  args = { index = "integer" },
  run = function(_, args)
    local result, err = rex.call("session.list", {})
    if result == nil then
      error(err, 0)
    end
    local session = (result.sessions or {})[args.index]
    if session ~= nil then
      rex.client.queue("session.select", { session_id = session.session_id })
    end
  end,
})

-- Import Ghostty's exact palette through the local app. Press Ctrl+L then G
-- once to apply it; Rex.app remembers the selection. Remote Control can stay off.
rex.action({
  name = "apply_gruvbox_dark_hard",
  title = "Apply Gruvbox Dark Hard",
  category = "View",
  run = function()
    rex.client.queue("client.appearance.switch_mode", { mode = "dark" })
    rex.client.queue("client.theme.import", {
      path = os.getenv("HOME") .. "/.config/rex/themes/Gruvbox Dark Hard",
    })
  end,
})

-- Ctrl+L is the leader for everything: press and release it, then the action
-- key. Escape cancels a sequence. Lowercase keys act on panes and tabs; Shift
-- moves up a level to sessions and windows.
local prefix = "ctrl+l>"

-- Panes. % and double quote must be spelled as unshifted keys plus Shift;
-- \ and - are easier-to-reach aliases for the same splits.
rex.bind(prefix .. "shift+5", "pane.split", { direction = "right" })
rex.bind(prefix .. "\\", "pane.split", { direction = "right" })
rex.bind(prefix .. "shift+'", "pane.split", { direction = "down" })
rex.bind(prefix .. "-", "pane.split", { direction = "down" })
rex.bind(prefix .. "space", "pane.split.auto")

rex.bind(prefix .. "h", "pane.focus", { direction = "left" })
rex.bind(prefix .. "j", "pane.focus", { direction = "down" })
rex.bind(prefix .. "k", "pane.focus", { direction = "up" })
rex.bind(prefix .. "l", "pane.focus", { direction = "right" })
rex.bind(prefix .. "o", "pane.focus_next")
rex.bind(prefix .. "shift+o", "pane.focus_previous")

rex.bind(prefix .. "shift+h", "pane.move", { direction = "left" })
rex.bind(prefix .. "shift+j", "pane.move", { direction = "down" })
rex.bind(prefix .. "shift+k", "pane.move", { direction = "up" })
rex.bind(prefix .. "shift+l", "pane.move", { direction = "right" })

rex.bind(prefix .. "z", "pane.zoom")
rex.bind(prefix .. "f", "pane.float")
rex.bind(prefix .. "=", "pane.balance")
rex.bind(prefix .. "x", "pane.close")
rex.bind(prefix .. "shift+b", "pane.move_to_new_tab")
rex.bind(prefix .. "shift+m", "pane.move_to_tab")
rex.bind(prefix .. "shift+r", "client.mode.enter", { name = "resize" })

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

-- Tabs.
rex.bind(prefix .. "c", "client.tab.new")
rex.bind(prefix .. "n", "client.tab.next")
rex.bind(prefix .. "p", "client.tab.previous")
rex.bind(prefix .. ",", "client.tab.rename")
rex.bind(prefix .. "shift+[", "client.tab.move.backward")
rex.bind(prefix .. "shift+]", "client.tab.move.forward")
rex.bind(prefix .. "shift+x", "client.tab.close")
for index = 1, 9 do
  rex.bind(prefix .. index, "client.tab.goto", { index = index })
end

-- Sessions (Herdr workspaces).
rex.bind(prefix .. "s", "session.switch")
rex.bind(prefix .. "shift+c", "session.new")
rex.bind(prefix .. "shift+n", "session.next")
rex.bind(prefix .. "shift+p", "session.previous")
rex.bind(prefix .. ".", "session.rename")
-- Herdr's Shift+5 session shortcut conflicts with its % split shortcut.
-- Keep % for splitting; use Alt+5 for session 5 instead.
for index = 1, 9 do
  local modifier = index == 5 and "alt+" or "shift+"
  rex.bind(prefix .. modifier .. index, "session_by_index", { index = index })
end

-- App, search, and appearance, plus a way to send the original clear key.
rex.bind(prefix .. "shift+;", "client.palette.toggle")
rex.bind(prefix .. "shift+s", "client.settings")
rex.bind(prefix .. "shift+w", "client.window.new")
rex.bind(prefix .. "b", "client.sidebar.toggle")
rex.bind(prefix .. "a", "client.sidebar.activity.toggle")
rex.bind(prefix .. "/", "client.find.open")
rex.bind(prefix .. "[", "client.prompt.previous")
rex.bind(prefix .. "]", "client.prompt.next")
rex.bind(prefix .. "d", "pane.go_to_directory")
rex.bind(prefix .. "i", "pane.insert_path")
rex.bind(prefix .. "t", "client.theme.change")
rex.bind(prefix .. "g", "apply_gruvbox_dark_hard")
rex.bind(prefix .. "shift+=", "client.font.increase")
rex.bind(prefix .. "shift+-", "client.font.decrease")
rex.bind(prefix .. "shift+0", "client.font.reset")
rex.bind(prefix .. "r", "client.config.reload")
rex.bind(prefix .. "ctrl+l", "pane.send_key", { key = "ctrl+l" })

-- Herdr's native macOS shortcuts; Rex's other defaults remain available.
rex.bind("cmd+t", "client.tab.new")
rex.bind("cmd+shift+n", "session.new")
rex.bind("cmd+alt+shift+n", "client.window.new")
rex.bind("cmd+d", "pane.split", { direction = "right" })
rex.bind("cmd+shift+d", "pane.split", { direction = "down" })
rex.bind("cmd+shift+]", "client.tab.next")
rex.bind("cmd+shift+[", "client.tab.previous")

rex.bind("cmd+alt+left", "pane.focus", { direction = "left" })
rex.bind("cmd+alt+down", "pane.focus", { direction = "down" })
rex.bind("cmd+alt+up", "pane.focus", { direction = "up" })
rex.bind("cmd+alt+right", "pane.focus", { direction = "right" })
rex.bind("cmd+alt+]", "pane.focus_next")
rex.bind("cmd+alt+[", "pane.focus_previous")
rex.bind("cmd+shift+enter", "pane.zoom")
rex.bind("cmd+w", "pane.close")
rex.bind("cmd+shift+w", "client.tab.close")
for index = 1, 9 do
  rex.bind("cmd+" .. index, "client.tab.goto", { index = index })
end

rex.bind("cmd+b", "client.sidebar.toggle")
rex.bind("cmd+=", "client.font.increase")
rex.bind("cmd+shift+=", "client.font.increase")
rex.bind("cmd+-", "client.font.decrease")
rex.bind("cmd+0", "client.font.reset")
rex.bind("cmd+,", "client.settings")
rex.bind("cmd+p", "session.switch")
rex.bind("cmd+shift+p", "client.palette.toggle")

-- Native terminal search (Rex does not currently expose Herdr's Vim copy mode).
rex.bind("cmd+f", "client.find.open")
rex.bind("cmd+g", "client.find.next")
rex.bind("cmd+shift+g", "client.find.previous")
