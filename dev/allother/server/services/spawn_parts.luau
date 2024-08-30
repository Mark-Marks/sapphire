local ReplicatedStorage = game:GetService("ReplicatedStorage")

local components = require(ReplicatedStorage.components)
local sapphire_ecr = require(ReplicatedStorage.Packages.sapphire_ecr)

local SpawnParts = {}

function SpawnParts.start()
    local spawner = sapphire_ecr.create_spawner(components.part, components.position, components.velocity)
    local part_template = Instance.new("Part")

    local max = 2147483647

    for _ = 1, 1_000 do
        local rand = Random.new(math.random(max))

        local part = part_template:Clone()
        part.Anchored = true
        part.Parent = workspace
        local handle = spawner.spawn_with_handle(part, Vector3.zero, Vector3.zero)
        local random_velocity =
            Vector3.new(rand:NextNumber(-0.5, 0.5), rand:NextNumber(-0.5, 0.5), rand:NextNumber(-0.5, 0.5))
        handle:set(components.velocity, random_velocity)
    end
end

return SpawnParts
