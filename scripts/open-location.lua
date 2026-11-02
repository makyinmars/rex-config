-- Run by the open_location action's picker (actions/panes.lua) as
--   rex do scripts/open-location.lua file=PATH line=N col=N nvim_block=ID origin_block=ID cwd=DIR
--
-- Opens the file in the Neovim running in nvim_block, through the socket
-- ~/.config/nvim/lua/rex/init.lua listens on, or in a new Neovim split beside
-- origin_block when there is none. Then focuses that pane.

local args = rex.args
local file = args.file
local line = tonumber(args.line) or 1
local col = tonumber(args.col) or 1
local tmp_dir = ((os.getenv("TMPDIR") or "/tmp"):gsub("/$", ""))
local rex_bin = os.getenv("REX_BIN_DIR") and (os.getenv("REX_BIN_DIR") .. "/rex") or "rex"

-- This script runs in the picker's floating pane, which closes as soon as it
-- exits and would take focus with it. Focus the target a moment later.
local function focus_later(block_id)
  rex.exec.start({
    "/bin/sh",
    "-c",
    'sleep 0.3; exec "$1" focus -s "$2" "$3"',
    "sh",
    rex_bin,
    rex.session_id,
    block_id,
  }, { detach = true, stdout = false, stderr = false })
end

local function vim_string(text)
  return "'" .. text:gsub("'", "''") .. "'"
end

local function shell_quote(text)
  return "'" .. text:gsub("'", "'\\''") .. "'"
end

local nvim_block = args.nvim_block
if nvim_block ~= nil and nvim_block ~= "" then
  local socket = string.format("%s/nvim-rex-%s.sock", tmp_dir, nvim_block:sub(-12))
  local expr = string.format("v:lua.require'rex'.open(%s, %d, %d)", vim_string(file), line, col)
  local result = rex.exec({ "nvim", "--server", socket, "--remote-expr", expr }, { timeout = 5 })
  if result ~= nil and result.ok then
    focus_later(nvim_block)
    return
  end
end

local created, err = rex.session.new_split({
  anchor_id = args.origin_block,
  direction = "horizontal",
  side = "after",
  layout = rex.layout.block({
    flavor = "com.superlogical.terminal.shell",
    options = {
      cwd = args.cwd,
      initial_input = string.format("nvim +%d %s\n", line, shell_quote(file)),
    },
  }),
})
if created == nil then
  error(err, 0)
end
focus_later(created.block_ids[1])
