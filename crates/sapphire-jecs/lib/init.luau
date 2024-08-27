--!strict
--!native
--!optimize 2
-- draft 1
local RunService = game:GetService("RunService")
local is_client = RunService:IsClient()

local fast_spawn = require(script.Parent.spawn)
local jecs = require(script.Parent.jecs)

local types = require(script.types)

--- !!Entities are f64s!!
export type entity<T = nil> = types.Entity<T>
local pair: <R, T>(relationship: entity, target: entity) -> entity = jecs.pair :: any

local world: types.World = jecs.World.new() :: any

local SapphireJecs = {}
--- @readonly
SapphireJecs.identifier = "sapphire-jecs"

SapphireJecs.world = world

type system = (number) -> ()

type event = "stepped" | "heartbeat" | "render_stepped"

local csystem: entity<system> = world:component()
local cloop = world:component()
local cdepends_on = world:component()
local cevent: entity<event> = world:component()

local cstepped = world:component()
local crender_stepped = world:component()
local cheartbeat = world:component()

local function collect_systems_under_loop(systems: { system }, loop: entity)
    for _, system in world:query(csystem):with(pair(cdepends_on, loop)):iter() do
        table.insert(systems, system)
    end

    for dependency in world:query(cloop):with(pair(cdepends_on, loop)):iter() do
        collect_systems_under_loop(systems, dependency)
    end
end

type runnables = {
    stepped: { system },
    heartbeat: { system },
    render_stepped: { system },
}
local function collect_runnables(existing: runnables)
    for loop, event in world:query(cevent):with(cloop):iter() do
        local systems = {}
        existing[event] = collect_systems_under_loop(systems, loop)
    end
end

local runnables: runnables = {
    stepped = {},
    heartbeat = {},
    render_stepped = {},
}

function SapphireJecs.extension()
    if is_client then
        world:add(crender_stepped, cloop)
        world:set(crender_stepped, cevent, "render_stepped")
    end

    world:add(cstepped, cloop)
    world:set(cstepped, cevent, "stepped")

    world:add(cheartbeat, cloop)
    world:set(cheartbeat, cevent, "heartbeat")

    RunService.Stepped:Connect(function(_, delta_time)
        for _, system in runnables.render_stepped do
            fast_spawn(system, delta_time)
        end
    end)

    RunService.Heartbeat:Connect(function(delta_time)
        for _, system in runnables.heartbeat do
            fast_spawn(system, delta_time)
        end
    end)

    RunService.RenderStepped:Connect(function(delta_time)
        for _, system in runnables.render_stepped do
            fast_spawn(system, delta_time)
        end
    end)
end

SapphireJecs.methods = {}

function SapphireJecs.methods.system(singleton)
    local method: (world: types.World) -> (delta_time: number) -> () = singleton.system
    local loop_type: event = singleton.loop_type or "stepped" :: any -- ? why does this need to be casted

    if loop_type ~= "stepped" and loop_type ~= "heartbeat" and loop_type ~= "render_stepped" then
        warn(
            `[sapphire-jecs] Singleton {singleton.identifier} tried to use a loop of type {loop_type}, which doesn't exist. Halting scheduling it's system.`
        )
        return
    end

    if loop_type == "render_stepped" and not RunService:IsClient() then
        loop_type = "heartbeat"
        warn(
            `[sapphire-jecs] Singleton {singleton.identifier} tried to use a render_stepped system on the server. Migrated to heartbeat.`
        )
    end

    local loop: entity = if loop_type == "stepped"
        then cstepped
        elseif loop_type == "heartbeat" then cheartbeat
        else crender_stepped

    local runner = method(world)
    local system = world:entity()
    world:set(system, csystem, runner)
    world:add(system, pair(cdepends_on, loop))
    collect_runnables(runnables)
end

return SapphireJecs
