local ReplicatedStorage = game:GetService("ReplicatedStorage")
local services = script.Parent.services
local extensions = script.Parent.extensions

local sapphire = require(ReplicatedStorage.Packages.sapphire)()

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
    :use(require(extensions.heartbeat_lifecycle))
    :register_singleton(services.a)
    :register_singletons(services)
    :start()
