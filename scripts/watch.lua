-- Run by scripts/watch.sh as `rex do --all scripts/watch.lua`.
--
-- Focus history: records, for every tab, the pane it has focused and the one
-- before, in ~/.local/state/rex-config/focus.json. The focus_last action reads
-- it (actions/panes.lua).
--
-- Bells: a bell from a pane you aren't in becomes a macOS notification, at
-- most one per pane every 30 seconds. Panes whose programs report status
-- (agents) are skipped, since Rex already notifies for those.

local home = os.getenv("HOME")
local focus_file = home .. "/.local/state/rex-config/focus.json"
local terminal = "com.superlogical.terminal"

local windows = {} -- window_id -> { session_id, current, previous }
local sessions = {} -- session_id -> { label, active_window, focused = { window_id -> block_id } }

local function save()
  local text = rex.json.encode({ windows = windows })
  local temp = focus_file .. ".tmp"
  local file = io.open(temp, "w")
  if file == nil then
    return
  end
  file:write(text)
  file:close()
  os.rename(temp, focus_file)
end

local function snapshot(session_id)
  local view = rex.session.view({ session_id = session_id })
  if view == nil then
    return
  end
  local changed, present, focused = false, {}, {}
  for _, window in ipairs(view.windows or {}) do
    local current = window.focused_block_id
    present[window.window_id] = true
    focused[window.window_id] = current
    local entry = windows[window.window_id]
    if entry == nil then
      windows[window.window_id] = { session_id = session_id, current = current }
      changed = true
    elseif current ~= nil and current ~= entry.current then
      entry.previous, entry.current = entry.current, current
      changed = true
    end
  end
  for window_id, entry in pairs(windows) do
    if entry.session_id == session_id and not present[window_id] then
      windows[window_id] = nil
      changed = true
    end
  end
  sessions[session_id] = { label = view.label, active_window = view.active_window_id, focused = focused }
  if changed then
    save()
  end
end

-- session_view_changed arrives in bursts; look once things settle.
local pending = {}
rex.on("session_view_changed", function(ctx)
  local session_id = ctx.session_id
  if session_id == nil then
    return
  end
  local timer = pending[session_id]
  if timer then
    timer:cancel()
  end
  pending[session_id] = rex.after(0.15, function()
    pending[session_id] = nil
    snapshot(session_id)
  end)
end)

rex.on("session_destroyed", function(_, ev)
  for window_id, entry in pairs(windows) do
    if entry.session_id == ev.session_id then
      windows[window_id] = nil
    end
  end
  sessions[ev.session_id] = nil
  save()
end)

local function notify(title, text)
  local clean = function(s)
    return (s or ""):gsub("[%c]", " ")
  end
  rex.exec({
    "/usr/bin/osascript",
    "-e",
    string.format("display notification %q with title %q", clean(text), clean(title)),
  }, { timeout = 5 })
end

local last_bell = {}
rex.on("terminal.bell", function(ctx)
  local block_id = ctx.block_id
  if block_id == nil then
    return
  end
  local session = sessions[ctx.session_id]
  if session and session.focused[session.active_window] == block_id then
    return -- the pane you're in, such as a shell's completion bell
  end
  local now = os.time()
  if last_bell[block_id] and now - last_bell[block_id] < 30 then
    return
  end
  last_bell[block_id] = now
  local status = rex.block.call(terminal, "program_status", { block_id = block_id })
  if status and status.records and #status.records > 0 then
    return
  end
  local title = rex.block.call(terminal, "title", { block_id = block_id })
  notify("Bell in " .. ((session and session.label) or "Rex"), title and title.title or "")
end)

-- Exit when the server goes away, so watch.sh starts a fresh copy once it's back.
rex.every(20, function()
  if rex.call("server.status", {}) == nil then
    rex.stop(1)
  end
end)

local list = rex.call("session.list", {})
for _, session in ipairs((list and list.sessions) or {}) do
  snapshot(session.session_id)
end
save()
