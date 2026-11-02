-- Appearance and help.

local common = require("lib.common")

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
      path = common.config_dir .. "/themes/Gruvbox Dark Hard",
    })
  end,
})

-- The README's keybinding tables in a floating pager.
rex.action({
  name = "show_keys",
  title = "Show Keybinding Help",
  category = "View",
  run = function()
    common.sh_float('PAGER="less -r +/Keybindings" glow -p "$1" 2>/dev/null || less +/Keybindings "$1"', {
      common.config_dir .. "/README.md",
    })
  end,
})
