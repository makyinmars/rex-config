-- Keeps scripts/watch.lua running. The configuration file never receives
-- events, so a `rex do --all` script records focus history (for focus_last)
-- and turns bells into notifications. scripts/watch.sh supervises it across
-- server restarts; this starts the supervisor when the configuration loads,
-- unless it is already running.

local common = require("lib.common")

local M = {}

local function running(pid_file)
  local file = io.open(pid_file, "r")
  if file == nil then
    return false
  end
  local pid = file:read("*l")
  file:close()
  if pid == nil or not pid:match("^%d+$") then
    return false
  end
  local ps = rex.exec({ "/bin/ps", "-p", pid, "-o", "command=" }, { timeout = 2 })
  return ps ~= nil and ps.ok and ps.stdout:find("watch.sh", 1, true) ~= nil
end

function M.ensure_running()
  if running(common.state_dir .. "/watch.pid") then
    return
  end
  local _, err = rex.exec.start({
    "/bin/sh",
    common.config_dir .. "/scripts/watch.sh",
    common.rex_bin,
    common.config_dir .. "/scripts/watch.lua",
    common.state_dir,
  }, { detach = true, stdout = false, stderr = false })
  if err ~= nil then
    rex.log("warn", "could not start scripts/watch.sh: " .. err)
  end
end

return M
