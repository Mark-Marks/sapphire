--!strict
--!native
--!optimize 2
-- draft 1
local RunService = game:GetService("RunService")
local is_client = RunService:IsClient()

local jabby = require(script.Parent.jabby)
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

local cname = jecs.Name

local pair = jecs.pair

local world = require(script.world)

local jutils = require(script.Parent.jecs_utils)
jutils.initialize(world)

local handle = jutils.handle
export type handle = jutils.handle
local ref = jutils.ref
local collect = jutils.collect
export type collect_signal_like<T...> = jutils.collect_signal_like<T...>
export type collect_verbose_signal_like<D, T...> = jutils.collect_verbose_signal_like<D, T...>
local replicator = jutils.replicator
export type replicator = jutils.replicator
local spawner = jutils.spawner
export type spawner<T...> = jutils.spawner<T...>
local command_buffer = jutils.command_buffer
export type command_buffer = jutils.command_buffer

table.insert(jabby.public, {
    class_name = "World",
    name = "world",
    world = world,
    debug = cname,
})
jabby.public.updated = true
local jabby_scheduler = jabby.scheduler.create("sapphire-jecs")

table.insert(jabby.public, jabby_scheduler)

local SapphireJecs = {}
--- @readonly
SapphireJecs.identifier = "sapphire-jecs"

SapphireJecs.world = world

--- What ends up being called every frame, not the singleton itself
type fn_ev<T = any> = ((T) -> ()) -> any
type sig_snake_ev<T = any> = { connect: (self: sig_snake_ev<T>, (T) -> ()) -> any, [any]: any }
type sig_pascal_ev<T = any> = { Connect: (self: sig_pascal_ev<T>, (T) -> ()) -> any, [any]: any }
export type event<T = any> = fn_ev<T> | sig_snake_ev<T> | sig_pascal_ev<T>

export type system = {
    run: (...any) -> (),
    name: string,
    id: number,
}

local csystem: entity<system> = world:component()
local cdepends_on = world:component()
local cevent: entity<event<number>> = world:component()
local tphase = world:entity()

local cpre_simulation = world:component()
local crender_stepped = world:component()
local cheartbeat = world:component()

local function collect_systems_under_phase(systems: { system }, phase: entity)
    for _, system in world:query(csystem):with(pair(cdepends_on, phase)):iter() do
        table.insert(systems, system)
    end

    for dependency in world:query(tphase):with(pair(cdepends_on, phase)):iter() do
        collect_systems_under_phase(systems, dependency)
    end
end

type runnables = { [event]: { system } }
local function collect_runnables(existing: runnables)
    for phase, event in world:query(cevent):with(tphase):iter() do
        existing[event] = {}
        collect_systems_under_phase(existing[event], phase)
    end
end

local runnables: runnables = {}
local registered_phases: { [string]: entity } = {}

--- @readonly
function SapphireJecs.extension()
    if is_client then
        world:add(crender_stepped, tphase)
        world:set(crender_stepped, cevent, RunService.RenderStepped)
        registered_phases["render_stepped"] = crender_stepped
    end

    world:add(cpre_simulation, tphase)
    world:set(cpre_simulation, cevent, RunService.PreSimulation)
    registered_phases["pre_simulation"] = cpre_simulation

    world:add(cheartbeat, tphase)
    world:set(cheartbeat, cevent, RunService.Heartbeat)
    registered_phases["heartbeat"] = cheartbeat

    local function runner(event: event): (...any) -> ()
        return function(...)
            for _, system in runnables[event] do
                local id = system.id
                local system_data = jabby_scheduler.system_data[id]
                if system_data.paused then
                    continue
                end

                jabby_scheduler:_mark_system_frame_start(id)
                system.run(...)
                jabby_scheduler:_mark_system_frame_end(id)
            end
        end
    end

    for _, event in world:query(cevent):with(tphase):iter() do
        local run = runner(event)
        if type(event) == "function" then
            event(run)
            continue
        end

        if event.connect then
            event:connect(run)
            continue
        end

        event:Connect(run)
    end
end

function SapphireJecs.register_components(components: { [string]: entity })
    for name, component in components do
        world:set(component, cname, name)
    end
end

--- @readonly
SapphireJecs.methods = {}

function SapphireJecs.methods.system(singleton: any)
    local method: (world: world) -> (delta_time: number) -> () = singleton.system
    local phase: string = singleton.phase or "heartbeat"
    local identifier: string = singleton.identifier

    local registered_phase = registered_phases[phase]
    if not registered_phase then
        warn(
            `[sapphire-jecs] Singleton {identifier} tried to use a phase of type {phase}, which doesn't exist. Halting scheduling it's system.`
        )
        return
    end

    if phase == "render_stepped" and not is_client then
        phase = "heartbeat"
        warn(
            `[sapphire-jecs] Singleton {identifier} tried to use a render_stepped system on the server. Migrated to heartbeat.`
        )
    end

    local run = method(world)
    local system_id = jabby_scheduler:register_system({
        name = identifier,
        phase = phase,
    })
    handle(world:entity())
        :set(csystem, {
            run = run,
            name = identifier,
            id = system_id,
        })
        :add(pair(cdepends_on, registered_phase))
    collect_runnables(runnables)
end

function SapphireJecs.phase(after: entity, event: event, name: string): entity
    if registered_phases[name] then
        error(`[sapphire-jecs] The phase {name} already exists`)
    end

    local phase = world:entity()
    handle(phase):add(tphase):add(pair(cdepends_on, after)):set(cevent, event)
    registered_phases[name] = phase
    return phase
end

SapphireJecs.ref = ref
SapphireJecs.collect = collect
SapphireJecs.handle = handle
SapphireJecs.replicator = replicator
SapphireJecs.spawner = spawner
SapphireJecs.command_buffer = command_buffer

--- Creates a new entity and returns its id.
--- @return entity
function SapphireJecs.entity(): entity
    return world:entity()
end

--- Creates a new entity and returns a handle to it.
--- @return handle
function SapphireJecs.entity_with_handle(): handle
    return handle(world:entity())
end

--- Reexport of JECS
SapphireJecs.jecs = jecs

return SapphireJecs
