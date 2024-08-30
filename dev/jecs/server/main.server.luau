--!strict
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local sapphire = require(ReplicatedStorage.Packages.sapphire)()
local sapphire_jecs = require(ReplicatedStorage.Packages.sapphire_jecs)
local sapphire_net = require(ReplicatedStorage.Packages.sapphire_net)

local services = ServerScriptService.services
local systems = services.systems

sapphire.signals.on_extension_registered:Connect(function(extension)
    print(`Registered extension {extension.identifier}`)
end)

sapphire.signals.on_singleton_registered:Connect(function(singleton)
    print(`Registered singleton {singleton.identifier}`)
end)

sapphire.signals.on_singleton_initialized:Connect(function(singleton)
    print(`Initialized singleton {singleton.identifier}`)
end)

sapphire.signals.on_singleton_started:Connect(function(singleton)
    print(`Started singleton {singleton.identifier}`)
end)

sapphire:use(sapphire_net):use(sapphire_jecs):register_singletons(services):register_singletons(systems):start()
