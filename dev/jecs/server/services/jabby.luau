local ReplicatedStorage = game:GetService("ReplicatedStorage")

local jabby = require(ReplicatedStorage.Packages.jabby)
local ecs = require(ReplicatedStorage.Packages.sapphire_jecs)

local components = require(ReplicatedStorage.components)

local jabby_service = {}

function jabby_service.start()
    jabby.set_check_function(function(player)
        return player.UserId == game.CreatorId
    end)
    ecs.register_components(components)
end

return jabby_service
