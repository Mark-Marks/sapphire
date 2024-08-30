--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local jecs = require(ReplicatedStorage.Packages.sapphire_jecs)
local components = require(ReplicatedStorage.components)

local spawn_parts = {}

function spawn_parts.start()
    local spawner = jecs.create_spawner(components.part, components.position, components.velocity)

    local max = 2147483647

    for _ = 1, 1_000 do
        local rand = Random.new(math.random(max))

        local part = Instance.new("Part")
        part.Anchored = true

        local random_velocity =
            Vector3.new(rand:NextNumber(-2.5, 2.5), rand:NextNumber(-2.5, 2.5), rand:NextNumber(-2.5, 2.5))
        local handle = spawner.spawn_with_handle(part, Vector3.zero, Vector3.zero)
        handle:set(components.velocity, random_velocity)

        part.Parent = workspace
    end
end

return spawn_parts
