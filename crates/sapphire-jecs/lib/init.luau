--!strict
--!native
--!optimize 2
-- draft 1
local RunService = game:GetService("RunService")
local is_client = RunService:IsClient()

local fast_spawn = require(script.Parent.spawn)
local jecs = require(script.Parent.jecs)
--- An i53, can be represented with an f64.
export type i53 = number
--- An i24, can be represented with an i32.
export type i24 = number
export type archetype = jecs.Archetype
export type pair = jecs.Pair
export type entity<T = nil> = jecs.Entity<T>
export type id<T = nil> = entity<T> | pair
export type world = jecs.World

local pair = jecs.pair

local world = require(script.world)
local handle = require(script.handle)
export type handle = handle.handle
local _ref = require(script.ref)
local ref = _ref.ref
local ref_on_created = _ref.on_created
local spawner_type = require(script.spawner_type)

local SapphireJecs = {}
--- @readonly
SapphireJecs.identifier = "sapphire-jecs"

SapphireJecs.world = world

--- What ends up being called every frame, not the singleton itself
export type system = (number) -> ()
--- Phase to run the system on
export type phase = "pre_simulation" | "heartbeat" | "render_stepped"

local csystem: entity<system> = world:component()
local cphase: entity<phase> = world:component()
local cdepends_on = world:component()
local cevent: entity<RBXScriptSignal<number>> = world:component()

local cpre_simulation = world:component()
local crender_stepped = world:component()
local cheartbeat = world:component()

local function collect_systems_under_phase(systems: { system }, phase: entity<phase>)
    for _, system in world:query(csystem):with(pair(cdepends_on, phase)):iter() do
        table.insert(systems, system)
    end

    for dependency in world:query(cphase):with(pair(cdepends_on, phase)):iter() do
        collect_systems_under_phase(systems, dependency)
    end
end

type runnables = { [RBXScriptSignal]: { system } }
local function collect_runnables(existing: runnables)
    for phase, event in world:query(cevent):with(cphase):iter() do
        existing[event] = {}
        collect_systems_under_phase(existing[event], phase)
    end
end

local runnables: runnables = {}

--- @readonly
function SapphireJecs.extension()
    if is_client then
        world:add(crender_stepped, cphase)
        world:set(crender_stepped, cevent, RunService.RenderStepped)
    end

    world:add(cpre_simulation, cphase)
    world:set(cpre_simulation, cevent, RunService.PreSimulation)

    world:add(cheartbeat, cphase)
    world:set(cheartbeat, cevent, RunService.Heartbeat)

    for _, event in world:query(cevent):with(cphase):iter() do
        event:Connect(function(delta_time)
            for _, system in runnables[event] do
                fast_spawn(system, delta_time)
            end
        end)
    end
end

--- @readonly
SapphireJecs.methods = {}

function SapphireJecs.methods.system(singleton)
    local method: (world: world) -> (delta_time: number) -> () = singleton.system
    local phase: phase = singleton.phase or "heartbeat" :: any -- ? why does this need to be casted

    if phase ~= "pre_simulation" and phase ~= "heartbeat" and phase ~= "render_stepped" then
        warn(
            `[sapphire-jecs] Singleton {singleton.identifier} tried to use a loop of type {phase}, which doesn't exist. Halting scheduling it's system.`
        )
        return
    end

    if phase == "render_stepped" and not is_client then
        phase = "heartbeat"
        warn(
            `[sapphire-jecs] Singleton {singleton.identifier} tried to use a render_stepped system on the server. Migrated to heartbeat.`
        )
    end

    local phase_component: entity = if phase == "pre_simulation"
        then cpre_simulation
        elseif phase == "heartbeat" then cheartbeat
        else crender_stepped

    local runner = method(world)
    local system = world:entity()
    world:set(system, csystem, runner)
    world:add(system, pair(cdepends_on, phase_component))
    collect_runnables(runnables)
end

--- Creates a handle to the given entity.
--- @param entity entity
--- @return handle
function SapphireJecs.handle(entity: entity): handle
    return handle.new(entity)
end

SapphireJecs.ref = ref
SapphireJecs.on_created = ref_on_created

--- Creates a new entity and returns its id.
--- @return entity
function SapphireJecs.spawn_entity(): entity
    return world:entity()
end

--- Creates a new entity and returns a handle to it.
--- @return handle
function SapphireJecs.spawn_entity_with_handle(): handle
    return handle.new(world:entity())
end

export type spawner<T...> = {
    --- Creates an entity with the given components.
    --- @param ... T...
    --- @return entity
    spawn: (T...) -> entity,
    --- Creates an entity with the given components and returns a handle to it.
    --- @param ... T...
    --- @return handle
    spawn_with_handle: (T...) -> handle,
}

local function create_spawner(...)
    local components = { ... }

    local function spawn(...)
        local passed = { ... }
        local entity = world:entity()

        for idx, component in components do
            world:set(entity, component, passed[idx])
        end

        return entity
    end

    local function spawn_with_handle(...)
        local passed = { ... }
        local entity = handle.new(world:entity())

        for idx, component in components do
            entity:set(component, passed[idx])
        end

        return entity
    end

    return {
        spawn = spawn,
        spawn_with_handle = spawn_with_handle,
    }
end

--- Creates an entity spawner.
--- ```luau
--- local spawner = sapphire_jecs.create_spawner(components.part, components.velocity, components.position)
--- for _ = 1, 1000 do
---     spawner.spawn(part_template:Clone(), Vector3.zero, Vector3.zero)
--- end
--- ```
--- @param ... T... -- Components to use.
--- @return spawner<T...>
SapphireJecs.create_spawner = (create_spawner :: any) :: spawner_type.create_spawner

--- A replicator keeps track of all entities with the passed components and their values -
--- whenever a component is changed (add, change, remove) and the replicator listens to it, it's also changed within the contained raw data.\
--- The developer can then calculate the difference on the server and send it to the client every time,
--- on which the difference is then applied to the world.\
--- Albeit it's called a replicator, it doesn't replicate the data by itself.
--- This allows the developer to use any networking libary to replicate the changes.
--- ```luau
--- -- server
--- local replicator = sapphire_jecs.create_replicator(component_a, component_b, ...)
---
--- function singleton.system()
---     return function()
---         local difference = replicator.calculate_difference()
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
--- local replicator = sapphire_jecs.create_replicator(component_a, component_b, ...)
---
--- function singleton.system()
---     return function()
---         for _, difference in data_replication_event.poll() do
---             replicator.apply_difference(difference)
---         end
---     end
--- end
--- ```
export type replicator = {
    --- Gets the full data representing the entire world.
    --- Useful for initial replication to every player.
    --- ```luau
    --- local replicator = sapphire_jecs.create_replicator(component_a, component_b, ...)
    ---
    --- Players.PlayerAdded:Connect(function(player)
    ---     data_replication_event.send_to(player, replicator.get_full_data())
    --- end)
    --- ```
    --- @return changes
    get_full_data: () -> changes,
    --- Calculates the difference between last sent data and currently stored data.
    --- ```luau
    --- local replicator = sapphire_jecs.create_replicator(component_a, component_b, ...)
    ---
    --- function singleton.system()
    ---     return function()
    ---         local difference = replicator.calculate_difference()
    ---         -- There might not be any difference
    ---         if not difference then
    ---             return
    ---         end
    ---         data_replication_event.send_to_all(difference)
    ---     end
    --- end
    --- ```
    --- @return changes? -- There might not be any difference
    calculate_difference: () -> changes?,
    --- Applies the difference to the current data.
    --- ```luau
    --- local replicator = sapphire_jecs.create_replicator(component_a, component_b, ...)
    ---
    --- function singleton.system()
    ---     return function()
    ---         for _, difference in data_replication_event.poll()
    ---             replicator.apply_difference(difference)
    ---         end
    ---     end
    --- end
    --- ```
    --- @param difference changes
    apply_difference: (difference: changes) -> (),
}

--- `map<component_id, array<entity_id>>`
type changes_added = { [i53]: { i53 } }
--- `map<component_id, array<entity_id, component_value>>`
type changes_set = { [i53]: { [i53]: unknown } }
--- `map<component_id, array<entity_id>>`
type changes_removed = { [i53]: { i53 } }

--- Example of how to implement for replication in `sapphire-net`
--- ```luau
--- local t = sapphire_net.data_types
--- local f64 = t.number(8)
--- t.struct({
---     added = t.map(f64, t.array(f64)),
---     set = t.map(f64, t.map(f64, t.unknown())),
---     removed = t.map(f64, t.array(f64)),
--- })
--- ```
export type changes = {
    --- `map<component_id, array<entity_id>>`
    added: changes_added,
    --- `map<component_id, map<entity_id, component_value>>`
    set: changes_set,
    --- `map<component_id, array<entity_id>>`
    removed: changes_removed,
}

--- A replicator keeps track of all entities with the passed components and their values -
--- whenever a component is changed (add, change, remove) and the replicator listens to it, it's also changed within the contained raw data.\
--- The developer can then calculate the difference on the server and send it to the client every time,
--- on which the difference is then applied to the world.\
--- Albeit it's called a replicator, it doesn't replicate the data by itself.
--- This allows the developer to use any networking libary to replicate the changes.
--- ```luau
--- -- server
--- local replicator = sapphire_jecs.create_replicator(component_a, component_b, ...)
---
--- function singleton.system()
---     return function()
---         local difference = replicator.calculate_difference()
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
--- local replicator = sapphire_jecs.create_replicator(component_a, component_b, ...)
---
--- function singleton.system()
---     return function()
---         for _, difference in data_replication_event.poll() do
---             replicator.apply_difference(difference)
---         end
---     end
--- end
--- ```
function SapphireJecs.create_replicator(...: entity): replicator
    local components = { ... }

    -- don't index a changes table start
    local raw_added: changes_added = {}
    local raw_set: changes_set = {}
    local raw_removed: changes_removed = {}

    local changes_added: changes_added = {}
    local changes_set: changes_set = {}
    local changes_removed: changes_removed = {}
    -- don't index a changes table end

    for _, component in components do
        world:set(component, jecs.OnAdd, function(entity)
            if not raw_added[component] then
                raw_added[component] = {}
            end
            if not changes_added[component] then
                changes_added[component] = {}
            end
            table.insert(raw_added[component], entity)
            table.insert(changes_added[component], entity)
        end)
        world:set(component, jecs.OnSet, function(entity, value)
            if not raw_set[component] then
                raw_set[component] = {}
            end
            if not changes_set[component] then
                changes_set[component] = {}
            end
            raw_set[component][entity] = value
            changes_set[component][entity] = value
        end)
        world:set(component, jecs.OnRemove, function(entity)
            if not raw_removed[component] then
                raw_removed[component] = {}
            end
            if not changes_removed[component] then
                changes_removed[component] = {}
            end
            table.insert(raw_removed[component], entity)
            table.insert(changes_removed[component], entity)
        end)
    end

    local function get_full_data(): changes
        return {
            added = raw_added,
            set = raw_set,
            removed = raw_removed,
        }
    end

    local function calculate_difference(): changes?
        local difference_added = changes_added
        local difference_set = changes_set
        local difference_removed = changes_removed
        changes_added = {}
        changes_set = {}
        changes_removed = {}

        local added_not_empty = next(difference_added) ~= nil
        local set_not_empty = next(difference_set) ~= nil
        local removed_not_empty = next(difference_removed) ~= nil

        if not added_not_empty and not set_not_empty and not removed_not_empty then
            return nil
        end

        return {
            added = difference_added,
            set = difference_set,
            removed = difference_removed,
        }
    end

    local function apply_difference(difference: changes)
        for component, entities in difference.added do
            for _, entity_id in entities do
                local entity = ref(`replicated-{entity_id}`)

                local exists = entity:has(component)
                if exists then
                    continue
                end
                entity:add(component)
            end
        end

        for component, entities in difference.set do
            for entity_id, value in entities do
                local entity = ref(`replicated-{entity_id}`)

                local existing_value = entity:get(component)
                if existing_value == value then
                    continue
                end
                entity:set(component, value)
            end
        end

        for component, entities in difference.removed do
            for _, entity_id in entities do
                local entity = ref(`replicated-{entity_id}`)

                local exists = entity:has(component)
                if exists then
                    continue
                end
                entity:remove(component)
            end
        end
    end

    return {
        get_full_data = get_full_data,
        calculate_difference = calculate_difference,
        apply_difference = apply_difference,
    }
end

--- Reexport of JECS
SapphireJecs.jecs = jecs

return SapphireJecs
