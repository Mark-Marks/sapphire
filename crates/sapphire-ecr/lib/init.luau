--!strict
local RunService = game:GetService("RunService")

local ecr = require(script.Parent.ecr)
local fast_spawn = require(script.Parent.spawn)
local sapphire = require(script.Parent.sapphire)

export type loop_type = "Stepped" | "Heartbeat" | "RenderStepped"
export type system = {
    --- Fires every `RunService.Stepped`
    runner: (delta_time: number) -> (),
    --- 1 = lowest priority
    priority: number?,
    --- Defaults to "Stepped"
    loop_type: loop_type?,
}

local World = {}
--- @readonly
World.identifier = "sapphire-ecr"
--- @readonly
World.methods = {}

World.registry = ecr.registry()
--- @readonly
World.stepped_systems = {} :: { system }
--- @readonly
World.heartbeat_systems = {} :: { system }
--- @readonly
World.render_stepped_systems = {} :: { system }

function World.extension()
    RunService.Stepped:Connect(function(delta_time)
        for _, system in World.stepped_systems do
            fast_spawn(system.runner, delta_time)
        end
    end)

    RunService.Heartbeat:Connect(function(delta_time)
        for _, system in World.heartbeat_systems do
            fast_spawn(system.runner, delta_time)
        end
    end)

    if RunService:IsClient() then
        RunService.RenderStepped:Connect(function(delta_time)
            for _, system in World.render_stepped_systems do
                fast_spawn(system.runner, delta_time)
            end
        end)
    end
end

export type spawner<T...> = {
    --- Creates an entity with the given components.
    --- @param ... T...
    --- @returns ecr.entity
    spawn: (T...) -> ecr.entity,
    --- Creates an entity with the given components and returns a handle to it.
    --- @param ... T...
    --- @returns ecr.Handle
    spawn_with_handle: (T...) -> ecr.Handle,
}

local function create_spawner(...)
    local components = { ... }

    local function spawn(...)
        local passed = { ... }
        local entity = World.spawn_entity()

        for index in components do
            World.registry:add(entity, passed[index])
        end

        return entity
    end

    local function spawn_with_handle(...)
        local passed = { ... }
        local entity = World.spawn_entity_with_handle()

        for index in components do
            entity:add(passed[index])
        end

        return entity
    end

    return {
        spawn = spawn,
        spawn_with_handle = spawn_with_handle,
    }
end

--- Creates a spawner.
--- ```luau
--- local spawner = sapphire_ecr.create_spawner(components.part, components.velocity, components.position)
--- for _ = 1, 1000 do
---     spawner.spawn(part_template:Clone(), Vector3.new(0, 0, 0), Vector3.new(0, 0, 0))
--- end
--- ```
--- @param ... T... -- Components to use.
--- @return spawner<T...>
function World.create_spawner<T...>(...: T...): spawner<T...>
    return create_spawner(...)
end

--- Creates an entity and returns it's id.
--- @return ecr.entity
function World.spawn_entity(): ecr.entity
    return World.registry:create()
end

--- Creates an entity and returns a handle to it.
--- @return ecr.Handle
function World.spawn_entity_with_handle(): ecr.Handle
    local entity = World.spawn_entity()
    return World.registry:handle(entity)
end

export type singleton = sapphire.singleton & {
    system: (registry: ecr.Registry) -> (delta_time: number) -> (),
    priority: number?,
    loop_type: loop_type?,
}

function World.methods.system(singleton: singleton)
    local method: (registry: ecr.Registry) -> (delta_time: number) -> () = singleton.scheduled_system
    local priority: number = singleton.priority or 1 :: any
    local loop_type: loop_type = singleton.loop_type or "Stepped"

    if loop_type ~= "Stepped" and loop_type ~= "Heartbeat" and loop_type ~= "RenderStepped" then
        warn(
            `[sapphire-ecr] Singleton {singleton.identifier} tried to use a loop of type {loop_type}, which doesn't exist. Halting scheduling it's system.`
        )
        return
    end

    if loop_type == "RenderStepped" and not RunService:IsClient() then
        loop_type = "Heartbeat"
        warn(
            `[sapphire-ecr] Singleton {singleton.identifier} tried to use a RenderStepped system on the server. Migrated to Heartbeat.`
        )
    end

    local systems: { system } = loop_type == "Stepped" and World.stepped_systems
        or loop_type == "Heartbeat" and World.heartbeat_systems
        or World.render_stepped_systems

    local runner = method(World.registry)
    table.insert(systems, { runner = runner, priority = priority })
    table.sort(systems, function(a, b)
        return a.priority > b.priority
    end)
end

return World
