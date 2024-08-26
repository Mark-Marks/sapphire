local ReplicatedStorage = game:GetService("ReplicatedStorage")

local components = require(ReplicatedStorage.components)
local sapphire_ecr = require(ReplicatedStorage.Packages.sapphire_ecr)

local update_position = {}

function update_position.system(registry: sapphire_ecr.Registry)
    local group = registry:group(components.position, components.velocity)
    return function(delta_time: number)
        for entity, position: Vector3, velocity: Vector3 in group do
            local new_position = position + (velocity * delta_time)
            registry:set(entity, components.position, new_position)
        end
    end
end

return update_position
