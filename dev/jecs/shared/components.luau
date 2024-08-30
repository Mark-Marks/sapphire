--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local jecs = require(ReplicatedStorage.Packages.sapphire_jecs)

return {
    part = jecs.world:component() :: jecs.entity<BasePart>,
    position = jecs.world:component() :: jecs.entity<Vector3>,
    velocity = jecs.world:component() :: jecs.entity<Vector3>,
}
