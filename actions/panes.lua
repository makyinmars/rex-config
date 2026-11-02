-- Panes: naming, Neovim-aware navigation, focus history, and opening file
-- locations printed in a pane.

local common = require("lib.common")

-- Rename the focused pane from a one-line prompt over it. Labels are what
-- `rex -b NAME` and agents match against.
rex.action({
  name = "rename_pane",
  title = "Rename Pane",
  category = "Pane",
  run = function(ctx)
    common.sh_float(
      'printf "Rename pane: "; read -r name && [ -n "$name" ] && rex block rename "$1" "$name"',
      { common.require_block(ctx) },
      { 0.25, 0.4, 0.5, 0.15 }
    )
  end,
})

-- One grid for Neovim splits and Rex panes. In a pane running Neovim with
-- ~/.config/nvim's Rex integration, the key goes to Neovim as F13-F16. Neovim
-- moves to the split that way, or at its edge runs `rex focus DIRECTION
-- --wrap`. Everywhere else focus moves between panes, wrapping at the edges.
local nvim_keys = {
  left = "\27[25~", -- F13
  down = "\27[26~", -- F14
  up = "\27[28~", -- F15
  right = "\27[29~", -- F16
}

rex.action({
  name = "navigate",
  title = "Focus Pane or Neovim Split",
  category = "Pane",
  args = { direction = "string" },
  run = function(ctx, args)
    local key = nvim_keys[args.direction]
    if key == nil then
      error("direction must be left, down, up, or right", 0)
    end
    if ctx.block_id ~= nil and common.is_rex_nvim(ctx.block_id) then
      common.check(rex.block.call(common.terminal, "write", { block_id = ctx.block_id, data = key }))
      return
    end
    rex.client.queue("pane.focus", { direction = args.direction, wrap = true })
  end,
})

-- tmux's last-pane: go back to the pane this tab had focused before. The focus
-- history comes from scripts/watch.lua, which lib/watcher.lua keeps running.
rex.action({
  name = "focus_last",
  title = "Focus Last Pane",
  category = "Pane",
  run = function(ctx)
    local block_id = common.require_block(ctx)
    local history = common.read_json(common.state_dir .. "/focus.json")
    if history == nil then
      error("No focus history yet: scripts/watch.lua isn't running. See the README.", 0)
    end
    local view = common.check(rex.session.view({}))
    local window = common.find_window(view, block_id)
    if window == nil then
      error("No tab holds the focused pane", 0)
    end
    local entry = (history.windows or {})[window.window_id] or {}
    -- The watcher may not have recorded the latest move yet.
    local target = entry.current ~= block_id and entry.current or entry.previous
    if target == nil or target == block_id then
      error("No earlier pane in this tab", 0)
    end
    for _, block in ipairs(common.window_blocks(window)) do
      if block.block_id == target then
        common.check(rex.session.focus_block({ block_id = target }))
        return
      end
    end
    error("The last pane has closed", 0)
  end,
})

-- Open a file location printed in the focused pane: compiler errors, test
-- failures, grep results, stack traces, and agents' @path#L references.
-- Locations that exist on disk are listed newest first in fzf, and the pick
-- opens in the Neovim already running in this tab, or in a new split.
local path = "[%w_%.%-/~@%+]+"
local location_patterns = {
  "(" .. path .. "):(%d+):(%d+)", -- path:line:col
  "(" .. path .. "):(%d+)", -- path:line
  "(" .. path .. ")%((%d+),(%d+)%)", -- path(line,col), as tsc prints it
  "(" .. path .. ")#L(%d+)", -- @path#L12, as agents write references
  "(" .. path .. "%.%a%w*)", -- a bare file name with an extension
}

local function is_file(file_path)
  local file = io.open(file_path, "r")
  if file == nil then
    return false
  end
  local _, err = file:read(1)
  file:close()
  return err == nil -- a directory opens but can't be read
end

local function resolve(token, cwd)
  token = token:gsub("^@", ""):gsub("[%.,;:]+$", "")
  local tries = { token }
  if token:match("^[ab]/") then -- git diff's a/ and b/ prefixes
    table.insert(tries, token:sub(3))
  end
  for _, try in ipairs(tries) do
    local full = try
    if common.starts_with(full, "~/") then
      full = common.home .. full:sub(2)
    elseif full:sub(1, 1) ~= "/" then
      full = cwd .. "/" .. full
    end
    full = full:gsub("/%./", "/")
    if is_file(full) then
      return full
    end
  end
  return nil
end

local function find_locations(lines, cwd, limit)
  local found, seen, checked = {}, {}, {}
  for index = #lines, math.max(1, #lines - 3000), -1 do
    for _, pattern in ipairs(location_patterns) do
      for token, line, col in lines[index]:gmatch(pattern) do
        if checked[token] == nil then
          checked[token] = resolve(token, cwd) or false
        end
        local full = checked[token]
        line = tonumber(line) or 1
        local key = full and (full .. ":" .. line)
        if full and not seen[key] and not (line == 1 and seen[full]) then
          seen[key], seen[full] = true, true
          local shown = full
          if common.starts_with(full, cwd .. "/") then
            shown = full:sub(#cwd + 2)
          elseif common.starts_with(full, common.home .. "/") then
            shown = "~" .. full:sub(#common.home + 1)
          end
          table.insert(found, { full, line, tonumber(col) or 1, string.format("%s:%d", shown, line) })
          if #found >= limit then
            return found
          end
        end
      end
    end
  end
  return found
end

local open_location_script = [[
list=$1
rex="${REX_BIN_DIR:+$REX_BIN_DIR/}rex"
pick() {
  fzf --delimiter='\t' --with-nth=4 --no-sort --prompt='open> ' \
    --header='Enter: open in Neovim' --color='bg:#1d2021,bg+:#3c3836' "$@" < "$list"
}
if command -v bat >/dev/null 2>&1; then
  sel=$(pick --preview 'bat --color=always --style=numbers --highlight-line {2} {1}' \
    --preview-window 'right,55%,+{2}-/2')
else
  sel=$(pick)
fi
rm -f "$list"
[ -n "$sel" ] || exit 0
file=$(printf '%s' "$sel" | cut -f1)
line=$(printf '%s' "$sel" | cut -f2)
col=$(printf '%s' "$sel" | cut -f3)
"$rex" do "$2" "file=$file" "line=$line" "col=$col" "nvim_block=$3" "origin_block=$4" "cwd=$5" >/dev/null ||
  { printf '\nPress Enter to close.'; read -r _; }
]]

rex.action({
  name = "open_location",
  title = "Open File Location in Neovim…",
  category = "Pane",
  keywords = "hints file line error path",
  run = function(ctx)
    local block_id = common.require_block(ctx)
    local cwd = common.cwd(block_id)
    local lines = common.split_lines(common.read_scrollback(block_id))
    local locations = find_locations(lines, cwd, 300)
    if #locations == 0 then
      error("No file locations in this pane", 0)
    end

    -- Prefer the Neovim in this pane, then any other in the tab.
    local nvim_block = ""
    local window = common.find_window(rex.session.view({}), block_id)
    local blocks = { { block_id = block_id } }
    for _, block in ipairs(window and common.window_blocks(window) or {}) do
      table.insert(blocks, block)
    end
    for _, block in ipairs(blocks) do
      if common.is_rex_nvim(block.block_id) then
        nvim_block = block.block_id
        break
      end
    end

    local rows = {}
    for _, location in ipairs(locations) do
      table.insert(rows, table.concat(location, "\t"))
    end
    local list = common.write_file(common.temp_path("rex-locations", block_id, "tsv"), table.concat(rows, "\n") .. "\n")
    common.sh_float(open_location_script, {
      list,
      common.config_dir .. "/scripts/open-location.lua",
      nvim_block,
      block_id,
      cwd,
    }, { 0.08, 0.1, 0.84, 0.75 })
  end,
})
