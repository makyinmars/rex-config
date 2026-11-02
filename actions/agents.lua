-- Agents: navigation between agent panes, the pane that needs attention, and
-- the agent list ~/.config/nvim/lua/rex/agent.lua sends context to.

local common = require("lib.common")

local needs_attention = { blocked = true, done = true, error = true }

rex.action({
  name = "focus_agent",
  title = "Focus Next Agent",
  category = "Pane",
  description = "Cycle through agent panes in every session. step = -1 goes backward.",
  args = { step = "integer?" },
  run = function(ctx, args)
    local step = args.step or 1
    local blocks = common.all_terminals()
    local current = step < 0 and #blocks + 1 or 0
    for index, block in ipairs(blocks) do
      if block.block_id == ctx.block_id then
        current = index
      end
    end
    for offset = 1, #blocks do
      local block = blocks[(current - 1 + step * offset) % #blocks + 1]
      if block.block_id ~= ctx.block_id and common.agent_app(block.block_id, block.session_id) then
        return common.focus_terminal(ctx, block)
      end
    end
    error("No other agent panes", 0)
  end,
})

-- The pane, in any session, whose program most recently became blocked, done,
-- or failed.
rex.action({
  name = "focus_attention",
  title = "Go to Pane Needing Attention",
  category = "Pane",
  run = function(ctx)
    local target, latest
    for _, block in ipairs(common.all_terminals()) do
      if block.block_id ~= ctx.block_id then
        for _, record in ipairs(common.status_records(block.block_id, block.session_id)) do
          if needs_attention[record.state] and (latest == nil or record.updated_at > latest) then
            target, latest = block, record.updated_at
          end
        end
      end
    end
    if target == nil then
      error("No pane needs attention", 0)
    end
    common.focus_terminal(ctx, target)
  end,
})

-- Every agent pane on the server, this session's first, with what Neovim's
-- picker shows: `rex do agent_panes --json`.
rex.action({
  name = "agent_panes",
  title = "List Agent Panes",
  category = "Pane",
  run = function(ctx)
    local here, elsewhere = {}, {}
    for _, block in ipairs(common.all_terminals()) do
      local app = common.agent_app(block.block_id, block.session_id)
      if app ~= nil then
        local state, title
        for _, record in ipairs(common.status_records(block.block_id, block.session_id)) do
          if record.id == nil then
            state, title = record.state, record.title
          end
          state = state or record.state
          title = title or record.title
        end
        local entry = {
          block_id = block.block_id,
          session_id = block.session_id,
          session_label = block.session_label,
          window_label = block.window_label,
          label = block.label,
          app = app,
          state = state or "idle",
          title = title,
        }
        table.insert(block.session_id == ctx.session_id and here or elsewhere, entry)
      end
    end
    for _, entry in ipairs(elsewhere) do
      table.insert(here, entry)
    end
    return { agents = here }
  end,
})

-- Focus a block by ID in any session, switching the app to it.
rex.action({
  name = "focus_pane",
  title = "Focus Pane by ID",
  category = "Pane",
  args = { block_id = "string", session_id = "string?" },
  run = function(ctx, args)
    local session_id = args.session_id or ctx.session_id
    local view = common.check(common.view(session_id))
    local window = common.find_window(view, args.block_id)
    if window == nil then
      error("No pane " .. args.block_id, 0)
    end
    common.focus_terminal(ctx, { session_id = session_id, window_id = window.window_id, block_id = args.block_id })
  end,
})
