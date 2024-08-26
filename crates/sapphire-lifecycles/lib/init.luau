--!strict
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local signal = require(script.Parent.signal)
type signal<T...> = signal.Signal<T...>

local on_heartbeat: signal<number> = signal()
local on_render_stepped: signal<number> = signal()
local on_stepped: signal<number, number> = signal()
local on_pre_simulation: signal<number> = signal()
local on_post_simulation: signal<number> = signal()
local on_pre_animation: signal<number> = signal()
local on_pre_render: signal<number> = signal()

local on_player_added: signal<Player> = signal()
local on_player_removing: signal<Player> = signal()
local on_game_shutdown: signal<()> = signal()

local is_client = RunService:IsClient()

local SapphireLifecycles = {}
SapphireLifecycles.identifier = "sapphire-lifecycles"

function SapphireLifecycles.extension()
    RunService.Heartbeat:Connect(function(delta_time)
        on_heartbeat:Fire(delta_time)
    end)

    RunService.Stepped:Connect(function(time_elapsed, delta_time)
        on_stepped:Fire(time_elapsed, delta_time)
    end)

    RunService.PreSimulation:Connect(function(delta_time)
        on_pre_simulation:Fire(delta_time)
    end)

    RunService.PostSimulation:Connect(function(delta_time)
        on_post_simulation:Fire(delta_time)
    end)

    if is_client then
        RunService.RenderStepped:Connect(function(delta_time)
            on_render_stepped:Fire(delta_time)
        end)

        RunService.PreRender:Connect(function(delta_time)
            on_pre_render:Fire(delta_time)
        end)

        RunService.PreAnimation:Connect(function(delta_time)
            on_pre_animation:Fire(delta_time)
        end)
    end

    Players.PlayerAdded:Connect(function(player)
        on_player_added:Fire(player)
    end)

    Players.PlayerRemoving:Connect(function(player)
        on_player_removing:Fire(player)
    end)

    game.Close:Connect(function()
        on_game_shutdown:Fire()
    end)
end

SapphireLifecycles.methods = {}

function SapphireLifecycles.methods.on_heartbeat(singleton: any)
    on_heartbeat:Connect(singleton.on_heartbeat)
end

function SapphireLifecycles.methods.on_render_stepped(singleton: any)
    if not is_client then
        warn(
            `[sapphire-lifecycles] Singleton {singleton.identifier} tried to register '.on_render_stepped' on the server`
        )
        return
    end
    on_render_stepped:Connect(singleton.on_render_steped)
end

function SapphireLifecycles.methods.on_stepped(singleton: any)
    on_stepped:Connect(singleton.on_stepped)
end

function SapphireLifecycles.methods.on_pre_simulation(singleton: any)
    on_pre_animation:Connect(singleton.on_pre_simulation)
end

function SapphireLifecycles.methods.on_post_simulation(singleton: any)
    on_post_simulation:Connect(singleton.on_post_simulation)
end

function SapphireLifecycles.methods.on_pre_animation(singleton: any)
    if not is_client then
        warn(
            `[sapphire-lifecycles] Singleton {singleton.identifier} tried to register '.on_pre_animation' on the server`
        )
        return
    end
    on_pre_animation:Connect(singleton.on_pre_animation)
end

function SapphireLifecycles.methods.on_pre_render(singleton: any)
    if not is_client then
        warn(`[sapphire-lifecycles] Singleton {singleton.identifier} tried to register '.on_pre_render' on the server`)
        return
    end
    on_pre_render:Connect(singleton.on_pre_render)
end

function SapphireLifecycles.methods.on_player_added(singleton: any)
    on_player_added:Connect(singleton.on_player_added)
end

function SapphireLifecycles.methods.on_player_removing(singleton: any)
    on_player_removing:Connect(singleton.on_player_removing)
end

function SapphireLifecycles.methods.on_game_shutdown(singleton: any)
    on_game_shutdown:Connect(singleton.on_game_shutdown)
end

return SapphireLifecycles
