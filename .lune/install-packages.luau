--!nocheck
local process = require("@lune/process")

local function start_process(cmd: string, cwd: string?)
    local arguments = string.split(cmd, " ")
    local command = arguments[1]
    table.remove(arguments, 1)

    process.spawn(command, arguments, { stdio = "forward", cwd = cwd })
end

start_process("wally install")
start_process("rojo sourcemap dev.project.json -o sourcemap.json")
start_process("wally-package-types --sourcemap sourcemap.json Packages/")
