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

local config_dir = os.getenv("HOME") .. "/.config/rex"
local terminal = "com.superlogical.terminal"
local shell = "com.superlogical.terminal.shell"

-- Import Ghostty's exact palette through the local app. Run it once from the
-- command palette (Ctrl+L then :); Rex.app remembers the selection. Remote
-- Control can stay off.
rex.action({
  name = "apply_gruvbox_dark_hard",
  title = "Apply Gruvbox Dark Hard",
  category = "View",
  run = function()
    rex.client.queue("client.appearance.switch_mode", { mode = "dark" })
    rex.client.queue("client.theme.import", {
      path = config_dir .. "/themes/Gruvbox Dark Hard",
    })
  end,
})

-- Run argv in a focused floating pane over the current tab. The pane closes
-- when the command exits.
local function float(argv, bounds)
  local _, err = rex.session.new_layer({
    bounds = bounds or { 0.05, 0.05, 0.9, 0.9 },
    focus = true,
    layout = rex.layout.block({ flavor = shell, options = { command = argv } }),
  })
  if err ~= nil then
    error(err, 0)
  end
end

-- Herdr's scrollback editor and the closest thing to its Vim copy mode: the
-- focused pane's screen and scrollback open in $EDITOR, at the bottom. The
-- temporary file is removed when the editor exits.
rex.action({
  name = "edit_scrollback",
  title = "Edit Pane Scrollback",
  category = "Pane",
  run = function(ctx)
    if ctx.block_id == nil then
      error("No focused pane", 0)
    end
    local args = { block_id = ctx.block_id, unwrap = true, trim = true, max_bytes = 983040 }
    local reply, err = rex.block.call(terminal, "format", args)
    if reply == nil then
      error(err, 0)
    end
    local parts, offset = { reply.content }, #reply.content
    while reply.id ~= nil and not reply.eof do
      reply, err = rex.block.call(terminal, "blob_read", {
        block_id = ctx.block_id,
        id = reply.id,
        offset = offset,
        max_bytes = 983040,
      })
      if reply == nil then
        error(err, 0)
      end
      if reply.data == "" then
        break
      end
      table.insert(parts, reply.data)
      offset = offset + #reply.data
    end

    local text = table.concat(parts)
    local last = #text
    while last > 0 and text:find("^%s", last) do
      last = last - 1
    end
    local dir = (os.getenv("TMPDIR") or "/tmp"):gsub("/$", "")
    local path = dir .. "/rex-scrollback-" .. ctx.block_id:sub(-12) .. ".txt"
    local file = assert(io.open(path, "w"))
    file:write(text:sub(1, last), "\n")
    file:close()
    float({ "sh", "-c", '${EDITOR:-nvim} + "$1"; rm -f "$1"', "sh", path })
  end,
})

-- Herdr's pane rename, as a one-line prompt over the pane. Labels are what
-- `rex -b NAME` and agents match against.
rex.action({
  name = "rename_pane",
  title = "Rename Pane",
  category = "Pane",
  run = function(ctx)
    if ctx.block_id == nil then
      error("No focused pane", 0)
    end
    float({
      "sh",
      "-c",
      'printf "Rename pane: "; read -r name && [ -n "$name" ] && rex block rename "$1" "$name"',
      "sh",
      ctx.block_id,
    }, { 0.25, 0.4, 0.5, 0.15 })
  end,
})

-- Herdr's keybinding help: this README in a floating pager.
rex.action({
  name = "show_keys",
  title = "Show Keybinding Help",
  category = "View",
  run = function()
    float({
      "sh",
      "-c",
      'PAGER="less -r +/Keybindings" glow -p "$1" 2>/dev/null || less +/Keybindings "$1"',
      "sh",
      config_dir .. "/README.md",
    })
  end,
})

-- Herdr's agent navigation. A pane is an agent when its program reports a
-- known app through the Program Status Protocol (Claude Code does), or when
-- its foreground process is a known agent. Program status also drives the
-- attention jump: blocked, done, and error records are what wants you.
local agents = {
  ["claude-code"] = true,
  claude = true,
  codex = true,
  opencode = true,
  pi = true,
  gemini = true,
  grok = true,
  aider = true,
  amp = true,
}
local needs_attention = { blocked = true, done = true, error = true }

-- Every terminal on the server, in session, tab, and layout order.
local function all_terminals()
  local list, err = rex.call("session.list", {})
  if list == nil then
    error(err, 0)
  end
  local blocks = {}
  for _, session in ipairs(list.sessions or {}) do
    local view = rex.session.view({ session_id = session.session_id })
    for _, window in ipairs((view and view.windows) or {}) do
      for _, layer in ipairs(window.layers or {}) do
        for _, block in ipairs(layer.blocks or {}) do
          if block.creator_name == terminal then
            table.insert(blocks, {
              session_id = session.session_id,
              window_id = window.window_id,
              block_id = block.block_id,
            })
          end
        end
      end
    end
  end
  return blocks
end

local function status_records(block_id)
  local reply = rex.block.call(terminal, "program_status", { block_id = block_id })
  return (reply and reply.records) or {}
end

local function is_agent(block_id)
  for _, record in ipairs(status_records(block_id)) do
    if agents[record.effective_app] then
      return true
    end
  end
  local reply = rex.block.call(terminal, "process", { block_id = block_id })
  local process = reply and reply.foreground
  if process == nil then
    return false
  end
  local name = (process.script or process.argv0 or process.name):match("([^/]+)$")
  return agents[(name:gsub("^%-", ""))] == true
end

-- Focus a block in any session, switching the app to that session if needed.
local function focus_terminal(ctx, target)
  local _, err = rex.session.focus_block({
    session_id = target.session_id,
    block_id = target.block_id,
  })
  if err ~= nil then
    error(err, 0)
  end
  if target.session_id ~= ctx.session_id then
    rex.client.queue("session.select", {
      session_id = target.session_id,
      window_id = target.window_id,
    })
  end
end

rex.action({
  name = "focus_agent",
  title = "Focus Next Agent",
  category = "Pane",
  description = "Cycle through agent panes in every session. step = -1 goes backward.",
  args = { step = "integer?" },
  run = function(ctx, args)
    local step = args.step or 1
    local blocks = all_terminals()
    local current = step < 0 and #blocks + 1 or 0
    for index, block in ipairs(blocks) do
      if block.block_id == ctx.block_id then
        current = index
      end
    end
    for offset = 1, #blocks do
      local block = blocks[(current - 1 + step * offset) % #blocks + 1]
      if block.block_id ~= ctx.block_id and is_agent(block.block_id) then
        return focus_terminal(ctx, block)
      end
    end
    error("No other agent panes", 0)
  end,
})

-- Herdr's "latest notification target": the pane, in any session, whose
-- program most recently became blocked, done, or failed.
rex.action({
  name = "focus_attention",
  title = "Go to Pane Needing Attention",
  category = "Pane",
  run = function(ctx)
    local target, latest
    for _, block in ipairs(all_terminals()) do
      if block.block_id ~= ctx.block_id then
        for _, record in ipairs(status_records(block.block_id)) do
          if needs_attention[record.state] and (latest == nil or record.updated_at > latest) then
            target, latest = block, record.updated_at
          end
        end
      end
    end
    if target == nil then
      error("No pane needs attention", 0)
    end
    focus_terminal(ctx, target)
  end,
})

-- Ctrl+L is the leader for everything: press and release it, then the action
-- key. Escape cancels a sequence. Keys match Herdr's wherever Rex has the same
-- feature or a Lua action above fills the gap, and Rex-only extras use keys
-- Herdr leaves free. Herdr keys for features Rex lacks stay unbound:
-- ; f F d G O.
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
rex.bind(prefix .. "shift+p", "rename_pane")
rex.bind(prefix .. "e", "edit_scrollback")
rex.bind(prefix .. "[", "edit_scrollback")

-- Agents, found by program status or process name, in every session.
rex.bind(prefix .. ".", "focus_agent", { step = 1 })
rex.bind(prefix .. ",", "focus_agent", { step = -1 })
rex.bind(prefix .. "o", "focus_attention")

-- Resize mode, as in Herdr: h/j/k/l or arrows resize, Shift for bigger steps,
-- = balances, Enter or Escape leaves. Exclusive so stray keys never reach the
-- terminal.
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
rex.bind(prefix .. "shift+t", "client.tab.rename")
rex.bind(prefix .. "shift+x", "client.tab.close")
rex.bind(prefix .. "shift+,", "client.tab.move.backward")
rex.bind(prefix .. "shift+.", "client.tab.move.forward")
for index = 1, 9 do
  rex.bind(prefix .. index, "client.tab.goto", { index = index })
end

-- Sessions (Herdr workspaces). g is Herdr's searchable navigator; Rex's
-- session picker is searchable too.
rex.bind(prefix .. "s", "session.switch")
rex.bind(prefix .. "g", "session.switch")
rex.bind(prefix .. "shift+n", "session.new")
rex.bind(prefix .. "shift+w", "session.rename")
rex.bind(prefix .. "shift+d", "session.close")
rex.bind(prefix .. "shift+[", "session.previous")
rex.bind(prefix .. "shift+]", "session.next")
-- Herdr's Shift+5 session shortcut conflicts with its % split shortcut.
-- Keep % for splitting; use Alt+5 for session 5 instead.
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
rex.bind(prefix .. "shift+=", "client.font.increase")
rex.bind(prefix .. "shift+-", "client.font.decrease")
rex.bind(prefix .. "shift+0", "client.font.reset")
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

-- Native terminal search. For Vim-style copying, Leader [ opens the scrollback
-- in $EDITOR.
rex.bind("cmd+f", "client.find.open")
rex.bind("cmd+g", "client.find.next")
rex.bind("cmd+shift+g", "client.find.previous")
