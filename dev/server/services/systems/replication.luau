local ReplicatedStorage = game:GetService("ReplicatedStorage")

local components = require(ReplicatedStorage.components)
local events = require(ReplicatedStorage.events)
local sapphire_ecr = require(ReplicatedStorage.Packages.sapphire_ecr)

local replicator = sapphire_ecr.create_replicator(components.position, components.velocity, components.part)

local replication_system = {}

local replication_event = events.data_replication.ecr_registry

function replication_system.start()
    events.test_namespace.loaded.listen(function(_, player)
        assert(player, "where player")
        replication_event.send_to(player, replicator.get_full_data())
    end)
end

function replication_system.system()
    return function(delta_time: number)
        local difference = replicator.calculate_difference()
        if not difference then
            return
        end
        replication_event.send_to_all(difference)
    end
end

return replication_system
