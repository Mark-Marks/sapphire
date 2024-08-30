local ReplicatedStorage = game:GetService("ReplicatedStorage")

local components = require(ReplicatedStorage.components)
local jecs = require(ReplicatedStorage.Packages.sapphire_jecs)

local update_position = {}

function update_position.system(world: jecs.world)
    return function(delta_time: number)
        for entity, position, velocity in world:query(components.position, components.velocity):iter() do
            local new_position = position + (velocity * delta_time)
            world:set(entity, components.position, new_position)
        end
    end
end

return update_position
