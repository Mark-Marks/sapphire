local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ecr = require(ReplicatedStorage.Packages.ecr)

return {
    position = ecr.component() :: Vector3,
    velocity = ecr.component() :: Vector3,
    part = ecr.component() :: BasePart,
}
