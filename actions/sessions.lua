-- Sessions and tabs: numbered switching, a project picker, and neorex.

local common = require("lib.common")

-- Neovim through neorex (github.com/alexrlocke/neorex), which shows each
-- Neovim window as a Rex pane, in a new tab at the focused pane's directory.
-- An interactive zsh runs it, so it gets the PATH typing neorex at the prompt
-- gets: Rex's login shell alone skips ~/.zshrc, which puts ~/.local/bin and
-- the Node toolchain on PATH. The tab closes when Neovim quits.
rex.action({
  name = "open_neorex",
  title = "Open Neovim in a New Tab",
  category = "Tab",
  run = function(ctx)
    local process = ctx.block_id and common.foreground(ctx.block_id)
    common.check(rex.session.new_window({
      layout = rex.layout.block({
        flavor = common.shell,
        options = { command = { "zsh", "-ic", "exec neorex" }, cwd = process and process.cwd },
      }),
    }))
  end,
})

-- Select a session by its position in the server's session order (new
-- sessions are appended).
rex.action({
  name = "session_by_index",
  title = "Go to Numbered Session",
  category = "Session",
  args = { index = "integer" },
  run = function(_, args)
    local result = common.check(rex.call("session.list", {}))
    local session = (result.sessions or {})[args.index]
    if session ~= nil then
      rex.client.queue("session.select", { session_id = session.session_id })
    end
  end,
})

-- Open a project as a session: switch to it when a session already has the
-- directory's name, otherwise create one with Neovim on the left (65%) and a
-- shell on the right. Neovim is typed into a shell, so quitting it leaves the
-- shell. select = false creates the session without switching to it.
rex.action({
  name = "open_project",
  title = "Open Project Session",
  category = "Session",
  description = "kind is session (value = session ID) or dir (value = path).",
  args = { kind = "string", value = "string", select = "boolean?" },
  run = function(_, args)
    local session_id
    if args.kind == "session" then
      session_id = args.value
    elseif args.kind == "dir" then
      local dir = args.value:gsub("/+$", "")
      local name = dir:match("([^/]+)$") or dir
      local list = common.check(rex.call("session.list", {}))
      for _, session in ipairs(list.sessions or {}) do
        if (session.label or ""):lower() == name:lower() then
          session_id = session.session_id
          break
        end
      end
      if session_id == nil then
        local layout = rex.layout.horizontal(
          0.65,
          rex.layout.block({ flavor = common.shell, options = { cwd = dir, initial_input = "nvim\n" } }),
          rex.layout.block({ flavor = common.shell, options = { cwd = dir } })
        )
        local created = common.check(rex.call("session.create", {
          label = name,
          initial_windows = { { layout = layout } },
        }))
        session_id = created.session_id
      end
    else
      error("kind must be session or dir", 0)
    end
    if args.select ~= false then
      rex.client.queue("session.select", { session_id = session_id })
    end
    return { session_id = session_id }
  end,
})

-- A fuzzy picker over running sessions and zoxide's directories, like
-- tmux-sessionizer or sesh.
local picker_script = [[
list=$1 client=$2
rex="${REX_BIN_DIR:+$REX_BIN_DIR/}rex"
sel=$(
  {
    cat "$list"
    zoxide query -l 2>/dev/null | awk -v home="$HOME" '{
      shown = $0
      if (index(shown, home) == 1) shown = "~" substr(shown, length(home) + 1)
      printf "dir\t%s\t  %s\n", $0, shown
    }'
  } | fzf --delimiter='\t' --with-nth=3.. --tiebreak=index --prompt='project> ' \
      --header='Enter: switch to the session, or open the directory as one' \
      --color='bg:#1d2021,bg+:#3c3836'
)
rm -f "$list"
[ -n "$sel" ] || exit 0
kind=$(printf '%s' "$sel" | cut -f1)
value=$(printf '%s' "$sel" | cut -f2)
"$rex" ${client:+-C "$client"} do open_project "kind=$kind" "value=$value" >/dev/null ||
  { printf '\nPress Enter to close.'; read -r _; }
]]

rex.action({
  name = "project_picker",
  title = "Open Project…",
  category = "Session",
  keywords = "sessionizer sesh zoxide",
  run = function(ctx)
    local list = common.check(rex.call("session.list", {}))
    local lines = {}
    for _, session in ipairs(list.sessions or {}) do
      local label = session.label or session.session_id
      local mark = session.session_id == ctx.session_id and "◆ " or "● "
      table.insert(lines, table.concat({ "session", session.session_id, mark .. label }, "\t"))
    end
    local path =
      common.write_file(common.temp_path("rex-projects", ctx.session_id, "tsv"), table.concat(lines, "\n") .. "\n")
    common.sh_float(picker_script, { path, ctx.client_id or "" }, { 0.15, 0.1, 0.7, 0.75 })
  end,
})
