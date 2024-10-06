local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local jabby = require(ReplicatedStorage.Packages.jabby)
local ecs = require(ReplicatedStorage.Packages.sapphire_jecs)

local components = require(ReplicatedStorage.components)

local JABBY_KEYCODE: Enum.KeyCode = Enum.KeyCode.F8

local jabby_controller = {}

function jabby_controller.start()
    jabby.set_check_function(function(player)
        return player.UserId == game.CreatorId
    end)
    ecs.register_components(components)

    local client = jabby.obtain_client()

    local open = false
    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then
            return
        end

        if input.KeyCode ~= JABBY_KEYCODE then
            return
        end

        if open then
            client.unmount_all()
            open = false
            return
        end

        client.spawn_app(client.apps.home :: any)
        open = true
    end)

    print(`jabby is running with keycode {JABBY_KEYCODE}`)
end

return jabby_controller
