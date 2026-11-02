-- Scrollback: editing, keyboard copy mode, copying the last command's output,
-- and scroll mode.

local common = require("lib.common")

-- The focused pane's screen and scrollback in $EDITOR (your full Neovim) in a
-- floating pane, at the bottom. The temporary file is removed when the editor
-- exits.
rex.action({
  name = "edit_scrollback",
  title = "Edit Pane Scrollback",
  category = "Pane",
  run = function(ctx)
    local block_id = common.require_block(ctx)
    local file =
      common.write_file(common.temp_path("rex-scrollback", block_id, "txt"), common.read_scrollback(block_id) .. "\n")
    common.sh_float('${EDITOR:-nvim} + "$1"; rm -f "$1"', { file })
  end,
})

-- tmux-style copy mode: the scrollback in a bare, fast Neovim
-- (nvim/copy-mode.lua) that starts at the bottom. Any yank copies to the
-- clipboard and closes it: v, move, y or Enter. q closes without copying.
-- Full-screen programs (Neovim, lazygit) have no scrollback, so for those
-- this shows what is on screen.
rex.action({
  name = "copy_mode",
  title = "Copy Mode",
  category = "Pane",
  run = function(ctx)
    local block_id = common.require_block(ctx)
    local file =
      common.write_file(common.temp_path("rex-copy", block_id, "txt"), common.read_scrollback(block_id) .. "\n")
    common.sh_float('nvim -u "$1" -R + "$2"; rm -f "$2"', { common.config_dir .. "/nvim/copy-mode.lua", file })
  end,
})

-- Copy the last command's output (and with command = true, the command too)
-- to the clipboard. Commands are found by the Starship prompt in
-- ~/.config/starship.toml: a "╭─" line, then "╰─❯ command". Change these if
-- the prompt changes.
local prompt_header = { "╭─" }
local prompt_line = { "╰─❯", "╰─❮" }

local function starts_with_any(line, prefixes)
  for _, prefix in ipairs(prefixes) do
    if common.starts_with(line, prefix) then
      return prefix
    end
  end
  return nil
end

rex.action({
  name = "copy_last_output",
  title = "Copy Last Command Output",
  category = "Pane",
  args = { command = "boolean?" },
  run = function(ctx, args)
    local block_id = common.require_block(ctx)
    local lines = common.split_lines(common.read_scrollback(block_id))
    -- The bottom prompt is the one waiting for input; the one before it ran
    -- the last command.
    local prompts = {}
    for index = #lines, 1, -1 do
      if starts_with_any(lines[index], prompt_line) then
        table.insert(prompts, index)
        if #prompts == 2 then
          break
        end
      end
    end
    if #prompts < 2 then
      error("No earlier command in this pane", 0)
    end
    local command_index, current = prompts[2], prompts[1]
    local first, last = command_index + 1, current - 1
    if last >= first and starts_with_any(lines[last], prompt_header) then
      last = last - 1
    end
    while last >= first and lines[last]:match("^%s*$") do
      last = last - 1
    end

    local output = {}
    if args.command then
      local prefix = starts_with_any(lines[command_index], prompt_line)
      table.insert(output, "$ " .. lines[command_index]:sub(#prefix + 1):gsub("^%s+", ""))
    end
    for index = first, last do
      table.insert(output, lines[index])
    end
    if #output == 0 then
      error("The last command printed nothing", 0)
    end
    common.copy_to_clipboard(table.concat(output, "\n") .. "\n")
    return { lines = #output }
  end,
})

-- Scroll mode: k and j (or the arrows and Page Up/Down) jump between shell
-- prompts, or page through full-screen programs such as Neovim and lazygit.
rex.action({
  name = "scroll_step",
  title = "Scroll Step",
  category = "Pane",
  args = { direction = "string" },
  run = function(ctx, args)
    local up = args.direction == "up"
    if ctx.block_id ~= nil and common.alternate_screen(ctx.block_id) then
      common.check(rex.block.call(common.terminal, "write", {
        block_id = ctx.block_id,
        data = up and "\27[5~" or "\27[6~",
      }))
    else
      rex.client.queue(up and "client.prompt.previous" or "client.prompt.next")
    end
  end,
})
