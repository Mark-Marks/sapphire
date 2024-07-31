local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local sapphire = require(ReplicatedStorage.Packages.sapphire)
local signal = require(ReplicatedStorage.Packages.signal)
local heartbeat_signal = signal()

local function extension()
    RunService.Heartbeat:Connect(function(delta_time)
        heartbeat_signal:Fire(delta_time)
    end)
end

local function heartbeat_registrant(singleton: sapphire.singleton)
    heartbeat_signal:Connect(singleton.on_heartbeat)
end

return {
    identifier = "heartbeat-lifecycle",
    extension = extension,
    methods = {
        on_heartbeat = heartbeat_registrant,
    },
}
