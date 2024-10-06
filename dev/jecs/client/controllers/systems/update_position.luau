--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local components = require(ReplicatedStorage.components)
local ecs = require(ReplicatedStorage.Packages.sapphire_jecs)

local update_position = {}

function update_position.system(world: ecs.world)
    return function(delta_time: number)
        for entity, part, position in world:query(components.part, components.position):iter() do
            part.Position = position
        end
    end
end

return update_position
