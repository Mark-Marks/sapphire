--!nocheck
local fs = require("@lune/fs")
local process = require("@lune/process")

local function start_process(cmd: string, cwd: string?)
    local arguments = string.split(cmd, " ")
    local command = arguments[1]
    table.remove(arguments, 1)

    process.spawn(command, arguments, { stdio = "forward", cwd = cwd })
end

start_process("lune run .lune/install-packages.luau")
start_process("curl -O https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/main/scripts/globalTypes.d.luau")
start_process("rojo sourcemap dev.project.json -o sourcemap.json")

for _, crate_name in fs.readDir("crates") do
    local cwd = `crates/{crate_name}`
    if not fs.isDir(cwd) then
        continue
    end

    start_process("rojo sourcemap default.project.json -o sourcemap.json", cwd)
    start_process(
        `luau-lsp analyze --definitions=globalTypes.d.luau --base-luaurc=.luaurc --sourcemap=sourcemap.json --settings=luau_lsp_settings.json --no-strict-dm-types --ignore Packages/**/*.lua --ignore Packages/**/*.luau --ignore {cwd}/Packages/**/*.lua --ignore {cwd}/Packages/**/*.luau {cwd}/lib/`
    )
end
