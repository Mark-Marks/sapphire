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

local SapphireEcr = {}
--- @readonly
SapphireEcr.identifier = "sapphire-ecr"

SapphireEcr.registry = ecr.registry()
--- @readonly
SapphireEcr.stepped_systems = {} :: { system }
--- @readonly
SapphireEcr.heartbeat_systems = {} :: { system }
--- @readonly
SapphireEcr.render_stepped_systems = {} :: { system }

function SapphireEcr.extension()
    RunService.Stepped:Connect(function(delta_time)
        for _, system in SapphireEcr.stepped_systems do
            fast_spawn(system.runner, delta_time)
        end
    end)

    RunService.Heartbeat:Connect(function(delta_time)
        for _, system in SapphireEcr.heartbeat_systems do
            fast_spawn(system.runner, delta_time)
        end
    end)

    if RunService:IsClient() then
        RunService.RenderStepped:Connect(function(delta_time)
            for _, system in SapphireEcr.render_stepped_systems do
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
        local entity = SapphireEcr.spawn_entity()

        for index, component in components do
            SapphireEcr.registry:set(entity, component, passed[index])
        end

        return entity
    end

    local function spawn_with_handle(...)
        local passed = { ... }
        local entity = SapphireEcr.spawn_entity_with_handle()

        for index, component in components do
            entity:set(component, passed[index])
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
function SapphireEcr.create_spawner<T...>(...: T...): spawner<T...>
    return create_spawner(...)
end

--- Creates an entity and returns it's id.
--- @return ecr.entity
function SapphireEcr.spawn_entity(): ecr.entity
    return SapphireEcr.registry:create()
end

--- Creates an entity and returns a handle to it.
--- @return ecr.Handle
function SapphireEcr.spawn_entity_with_handle(): ecr.Handle
    local entity = SapphireEcr.spawn_entity()
    return SapphireEcr.registry:handle(entity)
end

export type raw_data = {
    [ecr.entity]: { [number]: unknown },
}

--- A replicator keeps track of all entities with the passed components and their values -
--- whenever a component is changed (add, change, remove) and the replicator listens to it, it's also changed within the contained raw data.\
--- The developer can then calculate the difference on the server and send it to the client every time,
--- on which the difference is then applied to the registry.\
--- Albeit it's called a replicator, it doesn't replicate the data by itself.
--- It allows the developer to use any networking libary to replicate the changes.
--- ```luau
--- -- server
--- local replicator = sapphire_ecr.create_replicator(component_a, component_b, ...)
---
--- function singleton.system()
---     return function()
---         local difference = replicator.calculate_difference() --> buffer
---         -- There might not be any difference
---         if not difference then
---             return
---         end
---         data_replication_event.send_to_all(difference)
---     end
--- end
--- ```
--- ```luau
--- -- client
--- local replicator = sapphire_ecr.create_replicator(component_a, component_b, ...)
---
--- function singleton.system()
---     return function()
---         for _, difference in data_replication_event.poll()
---             replicator.apply_difference(difference)
---         end
---     end
--- end
--- ```
export type replicator = {
    --- Gets the full data representing the entire registry.
    --- Useful for initial replication to every player.
    --- ```luau
    --- local replicator = sapphire_ecr.create_replicator(component_a, component_b, ...)
    ---
    --- Players.PlayerAdded:Connect(function(player)
    ---     data_replication_event.send_to(player, replicator.get_full_data())
    --- end)
    --- ```
    --- @return raw_data
    get_full_data: () -> raw_data,
    --- Calculates the difference between last sent data and currently stored data.
    --- ```luau
    --- local replicator = sapphire_ecr.create_replicator(component_a, component_b, ...)
    ---
    --- function singleton.system()
    ---     return function()
    ---         local difference = replicator.calculate_difference() --> buffer
    ---         -- There might not be any difference
    ---         if not difference then
    ---             return
    ---         end
    ---         data_replication_event.send_to_all(difference)
    ---     end
    --- end
    --- ```
    --- @return raw_data? -- There might not be any difference
    calculate_difference: () -> raw_data?,
    --- Applies the difference to the current data.
    --- ```luau
    --- local replicator = sapphire_ecr.create_replicator(component_a, component_b, ...)
    ---
    --- function singleton.system()
    ---     return function()
    ---         for _, difference in data_replication_event.poll()
    ---             replicator.apply_difference(difference)
    ---         end
    ---     end
    --- end
    --- ```
    --- @param difference raw_data
    apply_difference: (difference: raw_data) -> (),
}

--- Creates a "replicator."\
--- A replicator keeps track of all entities with the passed components and their values -
--- whenever a component is changed (add, change, remove) and the replicator listens to it, it's also changed within the contained raw data.\
--- The developer can then calculate the difference on the server and send it to the client every time,
--- on which the difference is then applied to the registry.\
--- Albeit it's called a replicator, it doesn't replicate the data by itself.
--- It allows the developer to use any networking libary to replicate the changes.
--- ```luau
--- -- server
--- local replicator = sapphire_ecr.create_replicator(component_a, component_b, ...)
---
--- function singleton.system()
---     return function()
---         local difference = replicator.calculate_difference() --> buffer
---         -- There might not be any difference
---         if not difference then
---             return
---         end
---         data_replication_event.send_to_all(difference)
---     end
--- end
--- ```
--- ```luau
--- -- client
--- local replicator = sapphire_ecr.create_replicator(component_a, component_b, ...)
---
--- function singleton.system()
---     return function()
---         for _, difference in data_replication_event.poll()
---             replicator.apply_difference(difference)
---         end
---     end
--- end
--- ```
--- @param ... any -- Components to keep track of
--- @return replicator
function SapphireEcr.create_replicator(...): replicator
    local components = { ... }
    local changes: raw_data = {}
    local raw_data: raw_data = {}

    for _, component: number in components do
        SapphireEcr.registry:on_add(component):connect(function(entity, added_component)
            if not raw_data[entity] then
                raw_data[entity] = {}
                changes[entity] = {}
            end
            raw_data[entity][component] = added_component
            changes[entity][component] = added_component
        end)
        SapphireEcr.registry:on_change(component):connect(function(entity, changed_component)
            raw_data[entity][component] = changed_component
            if not changes[entity] then
                changes[entity] = {}
            end
            changes[entity][component] = changed_component
        end)
        SapphireEcr.registry:on_remove(component):connect(function(entity)
            raw_data[entity][component] = nil
            if not changes[entity] then
                changes[entity] = {}
            end
            changes[entity][component] = nil
        end)
    end

    local function get_full_data(): raw_data
        return raw_data
    end

    local function calculate_difference(): raw_data?
        local difference = changes
        changes = {}
        return if next(difference) ~= nil then difference else nil
    end

    local function apply_difference(difference: raw_data)
        for entity, entity_components in difference do
            if not SapphireEcr.registry:contains(entity) then
                SapphireEcr.registry:create(entity)
            end

            for component, value in entity_components do
                local existing_value = SapphireEcr.registry:try_get(entity, component :: any)
                if existing_value == value then
                    continue
                end
                SapphireEcr.registry:set(entity, component :: unknown, value)
            end
        end
    end

    return {
        get_full_data = get_full_data,
        calculate_difference = calculate_difference,
        apply_difference = apply_difference,
    }
end

export type singleton = sapphire.singleton & {
    system: (registry: ecr.Registry) -> (delta_time: number) -> (),
    priority: number?,
    loop_type: loop_type?,
}

--- @readonly
SapphireEcr.methods = {}

function SapphireEcr.methods.system(singleton: sapphire.singleton)
    local method: (registry: ecr.Registry) -> (delta_time: number) -> () = singleton.system
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

    local systems: { system } = loop_type == "Stepped" and SapphireEcr.stepped_systems
        or loop_type == "Heartbeat" and SapphireEcr.heartbeat_systems
        or SapphireEcr.render_stepped_systems

    local runner = method(SapphireEcr.registry)
    table.insert(systems, { runner = runner, priority = priority })
    table.sort(systems, function(a, b)
        return a.priority > b.priority
    end)
end

--- Reexport of ECR
SapphireEcr.ecr = ecr

export type entity = ecr.entity
export type Signal<T...> = ecr.Signal<T...>
export type Connection = ecr.Connection
export type Handle = ecr.Handle
export type View<T...> = ecr.View<T...>
export type Observer<T...> = ecr.Observer<T...>
export type Group<T...> = ecr.Group<T...>
export type Registry = ecr.Registry
export type Queue<T...> = ecr.Queue<T...>

return SapphireEcr
