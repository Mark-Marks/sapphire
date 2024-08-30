local ReplicatedStorage = game:GetService("ReplicatedStorage")
local controllers = script.Parent.controllers
local extensions = script.Parent.extensions

require(ReplicatedStorage.components) -- components need to be created before registry creation

local sapphire = require(ReplicatedStorage.Packages.sapphire)()
local sapphire_ecr = require(ReplicatedStorage.Packages.sapphire_ecr)
local sapphire_net = require(ReplicatedStorage.Packages.sapphire_net)

local heartbeat_lifecycle = require(extensions.heartbeat_lifecycle)

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

sapphire
    :use(sapphire_net)
    :use(heartbeat_lifecycle)
    :use(sapphire_ecr)
    :register_singletons(controllers)
    :register_singletons(controllers.systems)
    :start()
