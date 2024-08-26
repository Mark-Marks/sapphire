local ReplicatedStorage = game:GetService("ReplicatedStorage")

local components = require(ReplicatedStorage.components)
local events = require(ReplicatedStorage.events)
local sapphire_ecr = require(ReplicatedStorage.Packages.sapphire_ecr)

local replicator = sapphire_ecr.create_replicator(components.position, components.velocity, components.part)

local replication_system = {}

local replication_event = events.data_replication.ecr_registry

function replication_system.system()
    return function()
        for _, difference in replication_event.poll() do
            replicator.apply_difference(difference)
        end
    end
end

return replication_system
