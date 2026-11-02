---@meta
-- LuaCATS definitions for Rex's Lua API, for lua-language-server (.luarc.json
-- loads this directory). Rex doesn't ship its own yet; this follows
-- https://www.superlogical.com/rex/docs/reference/lua. Never loaded by Rex.

---@class rex.Context
---@field session_id? string
---@field block_id? string
---@field client_id? string
---@field origin? "key"|"palette"|"api"|"cli"|"timer"|string
---@field server? string

---@class rex.KeyEvent
---@field keybinding string The key that was pressed.
---@field prefix? string[] For a sequence, the keys before it.

---@class rex.Binding
---@field key string
---@field mode? string
---@field action? string
---@field fn? fun(ctx: rex.Context, ev: rex.KeyEvent): boolean?
---@field args? table
---@field source string

---@class rex.ActionSpec
---@field name string Lowercase letters, digits, and underscores.
---@field title string Shown in the command palette.
---@field run fun(ctx: rex.Context, args: table): any
---@field description? string
---@field category? string Defaults to "Actions".
---@field keywords? string
---@field args? table<string, string>|table Argument types ("string", "integer?", ...) or a JSON Schema.
---@field repeats? boolean Run again while the key is held.

---@class rex.Layout

---@class rex.LayoutBlockSpec
---@field flavor string Such as "com.superlogical.terminal.shell".
---@field options? rex.TerminalOptions
---@field label? string

---@class rex.TerminalOptions
---@field command? string[]
---@field shell? string
---@field cwd? string
---@field initial_input? string
---@field exit? { on_completion?: boolean }

---@class rex.ExecOptions
---@field cwd? string
---@field env? table<string, string|false>
---@field clear_env? boolean
---@field stdin? string|boolean
---@field timeout? number
---@field stdout? false|fun(chunk: string)
---@field stderr? false|fun(chunk: string)
---@field text? boolean
---@field detach? boolean Only for rex.exec.start.

---@class rex.ExecResult
---@field code integer
---@field signal? string
---@field stdout string
---@field stderr string
---@field timed_out boolean
---@field ok boolean

---@class rex.ExecHandle
---@field pid integer
local ExecHandle = {}
---@param seconds? number
---@return rex.ExecResult?, string?
function ExecHandle:wait(seconds) end
---@param data string
---@return boolean?, string?
function ExecHandle:write(data) end
function ExecHandle:close_stdin() end
---@param signal? string|integer
function ExecHandle:kill(signal) end
---@return boolean
function ExecHandle:running() end

---@class rex.Timer
local Timer = {}
function Timer:cancel() end
---@return boolean
function Timer:active() end

---@class rex.ServerApi
---@field session table<string, fun(args?: table): table?, string?>
---@field block { call: fun(creator: string, method: string, args?: table): table?, string? }
---@field call fun(method: string, args?: table): table?, string?

---@class rex
---@field args table Script arguments (rex do only).
---@field session_id string The script's session (rex do only).
---@field block_id? string The script's block (rex do only).
rex = {}

--- Bind a key or sequence ("ctrl+l>h", "mode/key") to an action or a function.
--- A function returns true to mark the key as handled.
---@param key string
---@param action string|fun(ctx: rex.Context, ev: rex.KeyEvent): boolean?
---@param args? table
function rex.bind(key, action, args) end

---@param key string|rex.Binding|{ mode: string }
---@param target? string|function
---@return integer
function rex.unbind(key, target) end

---@param name string
---@param options? { exclusive?: boolean }
function rex.mode(name, options) end

---@param filter? { key?: string, mode?: string, action?: string }
---@return rex.Binding[]
function rex.bindings(filter) end

---@return { name: string, exclusive: boolean, source: string }[]
function rex.modes() end

---@param spec rex.ActionSpec
function rex.action(spec) end

---@param name string
---@param args? table
---@return any result, string? err
function rex.invoke(name, args) end

---@param method string Full method name, such as "session.list".
---@param args? table
---@return table? result, string? err
function rex.call(method, args) end

--- Session methods; session_id is filled in when left out.
---@type table<string, fun(args?: table): table?, string?>
rex.session = {}

rex.block = {}

--- Call a block method. block_id defaults to the current block, and the
--- session to the current session (pass session_id for another one).
---@param creator string Such as "com.superlogical.terminal".
---@param method string
---@param args? table
---@return table? result, string? err
function rex.block.call(creator, method, args) end

rex.client = {}

--- Ask the client to perform one of its actions, such as "pane.zoom".
---@param name string
---@param args? table
function rex.client.queue(name, args) end

rex.layout = {}

---@param spec rex.LayoutBlockSpec
---@return rex.Layout
function rex.layout.block(spec) end

--- Side by side. ratio is a's share, 0 to 1.
---@param ratio number
---@param a rex.Layout
---@param b rex.Layout
---@return rex.Layout
function rex.layout.horizontal(ratio, a, b) end

--- One above the other. ratio is a's share, 0 to 1.
---@param ratio number
---@param a rex.Layout
---@param b rex.Layout
---@return rex.Layout
function rex.layout.vertical(ratio, a, b) end

--- Handle an event (rex do scripts only).
---@param event string Such as "session_view_changed" or "terminal.bell".
---@param fn fun(ctx: rex.Context, ev: table)
function rex.on(event, fn) end

---@param event string
---@param filter? table|fun(ev: table, ctx: rex.Context): boolean
---@param timeout? number
---@return table? ev, rex.Context|string ctx_or_err
function rex.wait(event, filter, timeout) end

---@param seconds number
function rex.sleep(seconds) end

---@param code? integer
function rex.stop(code) end

---@param seconds number
---@param fn fun(ctx: rex.Context)
---@return rex.Timer
function rex.after(seconds, fn) end

---@param seconds number
---@param fn fun(ctx: rex.Context)
---@return rex.Timer
function rex.every(seconds, fn) end

---@overload fun(argv: string[], opts?: rex.ExecOptions): rex.ExecResult?, string?
rex.exec = {}

---@param argv string[]
---@param opts? rex.ExecOptions
---@return rex.ExecHandle? handle, string? err
function rex.exec.start(argv, opts) end

rex.json = {}

---@param value any
---@param opts? { indent?: boolean }
---@return string? text, string? err
function rex.json.encode(value, opts) end

---@param text string
---@return any value, string? err
function rex.json.decode(text) end

---@param level_or_message string
---@param message? string
function rex.log(level_or_message, message) end

---@param spec { label: string, endpoints?: string[], endpoint?: string, id?: string, icon?: string }
function rex.host(spec) end

---@return string[]
function rex.servers() end

---@param label string
---@return rex.ServerApi
function rex.server(label) end
