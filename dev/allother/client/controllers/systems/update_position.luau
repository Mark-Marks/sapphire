local ReplicatedStorage = game:GetService("ReplicatedStorage")

local components = require(ReplicatedStorage.components)
local sapphire_ecr = require(ReplicatedStorage.Packages.sapphire_ecr)

local update_position = {}

function update_position.system(registry: sapphire_ecr.Registry)
    return function(delta_time: number)
        for entity, part: BasePart, position: Vector3 in registry:view(components.part, components.position) do
            part.Position = position
        end
    end
end

return update_position
