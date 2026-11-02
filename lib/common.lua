-- Helpers shared by the actions in actions/ and by lib/watcher.lua.

local M = {}

M.home = os.getenv("HOME")
M.config_dir = M.home .. "/.config/rex"
M.state_dir = M.home .. "/.local/state/rex-config"
M.tmp_dir = ((os.getenv("TMPDIR") or "/tmp"):gsub("/$", ""))
M.terminal = "com.superlogical.terminal"
M.shell = "com.superlogical.terminal.shell"

-- The server runs with a bare PATH (/usr/bin:/bin:...), so commands it starts
-- name their programs by full path. Its own rex sits in the app bundle.
local function find_rex()
  local candidates = {
    M.home
      .. "/Library/Application Support/com.superlogical.rex/RexServer/Versions/Current/Rex Server.app/Contents/MacOS/rex",
  }
  if os.getenv("REX_BIN_DIR") then
    table.insert(candidates, 1, os.getenv("REX_BIN_DIR") .. "/rex")
  end
  for _, path in ipairs(candidates) do
    local file = io.open(path, "r")
    if file then
      file:close()
      return path
    end
  end
  return "rex"
end
M.rex_bin = find_rex()

-- Rex calls return nil and a message instead of raising. Raise it, so the
-- action fails with that message.
function M.check(result, err)
  if result == nil then
    error(err, 0)
  end
  return result
end

function M.require_block(ctx)
  if ctx.block_id == nil then
    error("No focused pane", 0)
  end
  return ctx.block_id
end

-- Run argv in a focused floating pane over the current tab. The pane closes
-- when the command exits.
function M.float(argv, bounds)
  M.check(rex.session.new_layer({
    bounds = bounds or { 0.05, 0.05, 0.9, 0.9 },
    focus = true,
    layout = rex.layout.block({ flavor = M.shell, options = { command = argv } }),
  }))
end

-- Run a POSIX shell script in a floating pane, with args as $1, $2, ...
function M.sh_float(script, args, bounds)
  local argv = { "sh", "-c", script, "sh" }
  for _, arg in ipairs(args or {}) do
    table.insert(argv, arg)
  end
  M.float(argv, bounds)
end

-- The pane's screen and scrollback as plain text, one line per line the
-- program wrote, without trailing blank lines.
function M.read_scrollback(block_id)
  local args = { block_id = block_id, unwrap = true, trim = true, max_bytes = 983040 }
  local reply = M.check(rex.block.call(M.terminal, "format", args))
  local parts, offset = { reply.content }, #reply.content
  while reply.id ~= nil and not reply.eof do
    reply = M.check(rex.block.call(M.terminal, "blob_read", {
      block_id = block_id,
      id = reply.id,
      offset = offset,
      max_bytes = 983040,
    }))
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
  return text:sub(1, last)
end

function M.split_lines(text)
  local lines = {}
  for line in (text .. "\n"):gmatch("(.-)\n") do
    table.insert(lines, line)
  end
  return lines
end

function M.starts_with(text, prefix)
  return text:sub(1, #prefix) == prefix
end

function M.write_file(path, text)
  local file = assert(io.open(path, "w"))
  file:write(text)
  file:close()
  return path
end

-- A temporary file named after the pane, so each pane gets its own.
function M.temp_path(prefix, block_id, extension)
  return string.format("%s/%s-%s.%s", M.tmp_dir, prefix, block_id:sub(-12), extension)
end

function M.read_json(path)
  local file = io.open(path, "r")
  if file == nil then
    return nil
  end
  local text = file:read("*a")
  file:close()
  return (rex.json.decode(text))
end

function M.copy_to_clipboard(text)
  local result = M.check(rex.exec({ "/usr/bin/pbcopy" }, { stdin = text, env = { LC_CTYPE = "UTF-8" } }))
  if not result.ok then
    error("pbcopy failed: " .. result.stderr, 0)
  end
end

-- Block calls default to the current session; pass session_id for a block in
-- another one.

-- The process in the foreground of a terminal, or nil.
function M.foreground(block_id, session_id)
  local reply = rex.block.call(M.terminal, "process", { block_id = block_id, session_id = session_id })
  return reply and reply.foreground
end

function M.status_records(block_id, session_id)
  local reply = rex.block.call(M.terminal, "program_status", { block_id = block_id, session_id = session_id })
  return (reply and reply.records) or {}
end

function M.alternate_screen(block_id)
  local reply = rex.block.call(M.terminal, "modes", { block_id = block_id })
  return reply ~= nil and reply.screen == "alternate"
end

-- The directory the pane's foreground program is in.
function M.cwd(block_id)
  local process = M.foreground(block_id)
  if process and process.cwd then
    return process.cwd
  end
  local reply = rex.block.call(M.terminal, "pwd", { block_id = block_id })
  local url = reply and reply.pwd
  if url then
    local path = url:gsub("^file://[^/]*", ""):gsub("%%(%x%x)", function(hex)
      return string.char(tonumber(hex, 16))
    end)
    return path
  end
  return M.home
end

-- A pane is an agent when its program reports a known app through the Program
-- Status Protocol (Claude Code does), or when its foreground process is a
-- known agent.
M.agents = {
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

local function process_name(process)
  local name = (process.script or process.argv0 or process.name or ""):match("([^/]+)$") or ""
  return (name:gsub("^%-", ""))
end

-- The agent's app name, or nil when the pane isn't running an agent.
function M.agent_app(block_id, session_id)
  for _, record in ipairs(M.status_records(block_id, session_id)) do
    if M.agents[record.effective_app] then
      return record.effective_app
    end
  end
  local process = M.foreground(block_id, session_id)
  if process and M.agents[process_name(process)] then
    return process_name(process)
  end
  return nil
end

-- True when the pane runs Neovim with ~/.config/nvim's Rex integration, which
-- reports app=nvim and maps <F13>-<F16> for split navigation.
function M.is_rex_nvim(block_id)
  local process = M.foreground(block_id)
  if process == nil or process_name(process) ~= "nvim" then
    return false
  end
  for _, record in ipairs(M.status_records(block_id)) do
    if record.effective_app == "nvim" then
      return true
    end
  end
  return false
end

-- The socket ~/.config/nvim/lua/rex/init.lua listens on for the Neovim in a pane.
function M.nvim_socket(block_id)
  return string.format("%s/nvim-rex-%s.sock", M.tmp_dir, block_id:sub(-12))
end

-- Every terminal block in a window, in layer and layout order.
function M.window_blocks(window)
  local blocks = {}
  for _, layer in ipairs(window.layers or {}) do
    for _, block in ipairs(layer.blocks or {}) do
      if block.creator_name == M.terminal then
        table.insert(blocks, block)
      end
    end
  end
  return blocks
end

-- The window of a session view that holds block_id.
function M.find_window(view, block_id)
  for _, window in ipairs((view and view.windows) or {}) do
    for _, block in ipairs(M.window_blocks(window)) do
      if block.block_id == block_id then
        return window
      end
    end
  end
  return nil
end

-- A session's view. Actions run from the CLI (`rex do`) are attached only to
-- their own session, so attach to others first.
function M.view(session_id)
  local view, err = rex.session.view({ session_id = session_id })
  if view == nil and err ~= nil and err:find("not attached", 1, true) then
    if rex.call("session.attach", { session_id = session_id }) ~= nil then
      view, err = rex.session.view({ session_id = session_id })
    end
  end
  return view, err
end

-- Every terminal on the server, in session, tab, and layout order.
function M.all_terminals()
  local list = M.check(rex.call("session.list", {}))
  local blocks = {}
  for _, session in ipairs(list.sessions or {}) do
    local view = M.view(session.session_id) or {}
    for _, window in ipairs(view.windows or {}) do
      for _, block in ipairs(M.window_blocks(window)) do
        table.insert(blocks, {
          session_id = session.session_id,
          session_label = view.label,
          window_id = window.window_id,
          window_label = window.label,
          block_id = block.block_id,
          label = block.label,
        })
      end
    end
  end
  return blocks
end

-- Focus a block in any session, switching the app to that session if needed.
function M.focus_terminal(ctx, target)
  M.check(rex.session.focus_block({
    session_id = target.session_id,
    block_id = target.block_id,
  }))
  if target.session_id ~= ctx.session_id then
    rex.client.queue("session.select", {
      session_id = target.session_id,
      window_id = target.window_id,
    })
  end
end

return M
