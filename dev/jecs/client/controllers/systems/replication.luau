--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local jecs = require(ReplicatedStorage.Packages.sapphire_jecs)
local components = require(ReplicatedStorage.components)
local events = require(ReplicatedStorage.events)

local replicator = jecs.create_replicator(components.part, components.position, components.velocity)
local replication_event = events.data_replication.jecs_world

local replication = {}

function replication.start()
    events.data_replication.loaded.send()
end

function replication.system()
    return function(delta_time: number)
        for _, difference in replication_event.poll() do
            replicator.apply_difference(difference)
        end
    end
end

return replication
