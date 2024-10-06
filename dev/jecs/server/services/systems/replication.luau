--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ecs = require(ReplicatedStorage.Packages.sapphire_jecs)
local components = require(ReplicatedStorage.components)
local events = require(ReplicatedStorage.events)

local replicator = ecs.replicator(components.part, components.position, components.velocity)
local replication_event = events.data_replication.jecs_world

local replication = {}

function replication.start()
    events.data_replication.loaded.listen(function(_, player)
        assert(player, "where player")
        replication_event.send_to(player, replicator.get_full_data())
    end)
end

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
