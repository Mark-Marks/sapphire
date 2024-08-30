--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local jecs = require(ReplicatedStorage.Packages.sapphire_jecs)
local components = require(ReplicatedStorage.components)
local events = require(ReplicatedStorage.events)

local replicator = jecs.create_replicator(components.part, components.position, components.velocity)
local replication_event = events.data_replication.jecs_world

local replication = {}

function replication.system()
    return function(delta_time: number)
        local difference = replicator.calculate_difference()
        if not difference then
            return
        end
        replication_event.send_to_all(difference)
    end
end

return replication
