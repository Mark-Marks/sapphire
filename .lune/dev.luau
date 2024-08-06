--!nocheck
local process = require("@lune/process")
local task = require("@lune/task")

local function start_process(cmd: string, cwd: string?)
    local arguments = string.split(cmd, " ")
    local command = arguments[1]
    table.remove(arguments, 1)

    process.spawn(command, arguments, { stdio = "forward", cwd = cwd })
end

task.spawn(start_process, "rojo sourcemap dev.project.json -o sourcemap.json --watch")
task.spawn(start_process, "rojo serve dev.project.json")
