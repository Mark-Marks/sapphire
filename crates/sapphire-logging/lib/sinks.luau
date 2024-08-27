--!strict
local RunService = game:GetService("RunService")
local platform_icon = if RunService:IsServer() then "[🗼]" else "[💻]"

local types = require(script.Parent.types)

--- Roblox logging sink.
local roblox: types.sink = function(log)
    if log.type == "debug" then
        print(`[{platform_icon}][🕒{log.timestamp.clock}][🔨]: {log.msg}`)
    elseif log.type == "info" then
        print(`[{platform_icon}][🕒{log.timestamp.clock}][ℹ️]: {log.msg}`)
    elseif log.type == "warn" then
        warn(`[{platform_icon}][🕒{log.timestamp.clock}][⚠️]: {log.msg}`)
    elseif log.type == "error" then
        warn(`[{platform_icon}][🕒{log.timestamp.clock}][✖️]: {log.msg}\n{log.trace}`)
    elseif log.type == "fatal" then
        task.spawn(error, `[{platform_icon}][🕒{log.timestamp.clock}][❌]: {log.msg}\n{log.trace}`, 0)
    end
end

return {
    roblox = roblox,
}
