--!nocheck
local process = require("@lune/process")

local function start_process(cmd: string, cwd: string?)
    local arguments = string.split(cmd, " ")
    local command = arguments[1]
    table.remove(arguments, 1)

    process.spawn(command, arguments, { stdio = "forward", cwd = cwd })
end

start_process("lune run .lune/analyze.luau")
start_process("stylua crates/")
start_process("selene crates/")
