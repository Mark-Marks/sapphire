--!nocheck
local fs = require("@lune/fs")
local process = require("@lune/process")

local function start_process(cmd: string, cwd: string?)
    local arguments = string.split(cmd, " ")
    local command = arguments[1]
    table.remove(arguments, 1)

    process.spawn(command, arguments, { stdio = "forward", cwd = cwd })
end

for _, crate_name in fs.readDir("crates") do
    local cwd = `crates/{crate_name}`
    if not fs.isDir(cwd) then
        continue
    end

    start_process("wally install", cwd)
end
