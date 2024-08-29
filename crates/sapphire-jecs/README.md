# sapphire-jecs
A lightweight scheduler + niceties (replication, etc.) for [Ukendio/jecs](https://github.com/Ukendio/jecs) for [Mark-Marks/sapphire](https://github.com/Mark-Marks/sapphire)

# Installation
1. Install it with wally
```toml
[dependencies]
sapphire_jecs = "mark-marks/sapphire-jecs@LATEST" # replace LATEST with the latest version
```
2. `wally install`
3. Extend sapphire with it
```luau
local sapphire_jecs = require("@pkg/sapphire_jecs")

sapphire
    :use(sapphire_jecs)
```

# API

## Exports

### .world
```luau
type world = world
```

### .jecs
Reexport of Jecs
```luau
SapphireJecs.jecs = jecs
```

## Types

### phase
Phase to run the system on
```luau
type phase = "pre_simulation" | "heartbeat" | "render_stepped"
```

### system
What ends up being called every frame, not the singleton itself
```luau
type system = (
    delta_time: number
) -> ()
```

### spawner<T...>
```luau
type spawner<T...> = {
    spawn: (T...) -> entity,
    spawn_with_handle: (T...) -> handle,
}
```

### changes_added
`map<component_id, array<entity_id>>`
```luau
type changes_added = { [i53]: { i53 } }
```

### changes_set
`map<component_id, array<entity_id, component_value>>`
```luau
type changes_set = { [i53]: { [i53]: unknown } }
```

### changes_removed
`map<component_id, array<entity_id>>`
```luau
type changes_removed = { [i53]: { i53 } }
```

### changes
Example of how to implement for replication in `sapphire-net`
```luau
local t = sapphire_net.data_types
local f64 = t.number(8)
t.struct({
    added = t.map(f64, t.array(f64)),
    set = t.map(f64, t.map(f64, t.unknown())),
    removed = t.map(f64, t.array(f64)),
})
```
```luau
type type changes = {
    added: changes_added,
    set: changes_set,
    removed: changes_removed,
}
```

### replicator
```luau
type replicator = {
    get_full_data: () -> changes,
    calculate_difference: () -> changes?,
    apply_difference: (difference: changes) -> (),
}
```

### i53
An i53, can be represented with an f64.
```luau
type i53 = number
```

### i24
An i24, can be represented with an i32.
```luau
type i24 = number
```

### archetype
```luau
type archetype = jecs.Archetype
```

### pair
```luau
type pair = jecs.Pair
```

### entity<T = nil>
```luau
type entity<T = nil> = jecs.Entity<T>
```

### id<T = nil>
```luau
type id<T = nil> = entity<T> | pair
```

### world
```luau
type world = jecs.World
```

### handle
```luau
type handle = {
    __index: interface,

    new: (entity: entity) -> handle,

    --- Checks if the entity has all of the given components
    has: (self: handle, ...id) -> boolean,
    --- Retrieves the value of up to 4 components. These values may be nil.
    get: (<A>(self: handle, id<A>) -> A?)
        & (<A, B>(self: handle, id<A>, id<B>) -> (A?, B?))
        & (<A, B, C>(self: handle, id<A>, id<B>, id<C>) -> (A?, B?, C?))
        & (<A, B, C, D>(self: handle, id<A>, id<B>, id<C>, id<D>) -> (A?, B?, C?, D?)),
    --- Adds a component to the entity with no value
    add: <T>(self: handle, id: id<T>) -> handle,
    --- Assigns a value to a component on the given entity
    set: <T>(self: handle, id: id<T>, data: T) -> handle,
    --- Removes a component from the given entity
    remove: (self: handle, id: id) -> handle,
    --- Deletes the entity and all its related components and relationships. **Does not** refer to deleting the handle
    delete: (self: handle) -> (),
    --- Gets the entitys id
    id: (self: handle) -> entity,
}
```

## Registered methods

### .system()
Registers a system.
```luau
(
    singleton: sapphire.singleton
) -> ()
```
Singletons need to follow the following format:
```luau
type format = {
    system: (world: world) -> (delta_time: number) -> (),
    --- Defaults to `heartbeat`
    phase: phase?,
}
```
Systems on the server that use `RenderStepped` will be migrated to `Heartbeat`.

## Functions

### .spawn_entity()
Creates an entity and returns its id.
```luau
() -> entity
```

### .spawn_entity_with_handle()
Creates an entity and returns a handle to it.
```luau
() -> handle
```

### .create_spawner()
Creates a spawner.
```luau
<T...>(
    ...: T...
) -> spawner<T...>
```
```luau
local spawner = sapphire_jecs.create_spawner(components.part, components.velocity, components.position)
for _ = 1, 1000 do
    spawner.spawn(part_template:Clone(), Vector3.zero, Vector3.zero)
end
```

### .create_replicator
Creates a "replicator"
```luau
(
    ...
) -> replicator
```
A replicator keeps track of all entities with the passed components and their values -
whenever a component is changed (add, change, remove) and the replicator listens to it, it's also changed within the contained raw data.\
The developer can then calculate the difference on the server and send it to the client every time,
on which the difference is then applied to the world.\
Albeit it's called a replicator, it doesn't replicate the data by itself.
It allows the developer to use any networking libary to replicate the changes.
```luau
-- server
local replicator = sapphire_jecs.create_replicator(component_a, component_b, ...)

function singleton.system()
    return function()
        local difference = replicator.calculate_difference()
        -- There might not be any difference
        if not difference then
            return
        end
        data_replication_event.send_to_all(difference)
    end
end
```
```luau
-- client
local replicator = sapphire_jecs.create_replicator(component_a, component_b, ...)

function singleton.system()
    return function()
        for _, difference in data_replication_event.poll() do
            replicator.apply_difference(difference)
        end
    end
end
```

## spawner<T...>

### .spawn()
Creates an entity with the given components.
```luau
(
    T...
) -> entity
```

### .spawn_with_handle()
Creates an entity with the given components and returns a handle to it.
```luau
(
    T...
) -> handle
```

## replicator
A replicator keeps track of all entities with the passed components and their values -
whenever a component is changed (add, change, remove) and the replicator listens to it, it's also changed within the contained raw data.\
The developer can then calculate the difference on the server and send it to the client every time,
on which the difference is then applied to the world.\
Albeit it's called a replicator, it doesn't replicate the data by itself.
It allows the developer to use any networking libary to replicate the changes.
```luau
-- server
local replicator = sapphire_jecs.create_replicator(component_a, component_b, ...)

function singleton.system()
    return function()
        local difference = replicator.calculate_difference()
        -- There might not be any difference
        if not difference then
            return
        end
        data_replication_event.send_to_all(difference)
    end
end
```
```luau
-- client
local replicator = sapphire_jecs.create_replicator(component_a, component_b, ...)

function singleton.system()
    return function()
        for _, difference in data_replication_event.poll() do
            replicator.apply_difference(difference)
        end
    end
end
```

### .get_full_data()
Gets the full data representing the entire world.
Useful for initial replication to every player.
```luau
() -> raw_data
```
```luau
local replicator = sapphire_ecr.create_replicator(component_a, component_b, ...)

Players.PlayerAdded:Connect(function(player)
    data_replication_event.send_to(player, replicator.get_full_data())
end)
```

### .calculate_difference()
Calculates the difference between last sent data and currently stored data.
```luau
() -> changes?
```
```luau
local replicator = sapphire_jecs.create_replicator(component_a, component_b, ...)

function singleton.system()
    return function()
        local difference = replicator.calculate_difference()
        -- There might not be any difference
        if not difference then
            return
        end
        data_replication_event.send_to_all(difference)
    end
end
```

### .apply_difference()
Applies the difference to the current data.
```luau
(
    difference: changes
) -> ()
```
```luau
local replicator = sapphire_jecs.create_replicator(component_a, component_b, ...)

function singleton.system()
    return function()
        for _, difference in data_replication_event.poll()
            replicator.apply_difference(difference)
        end
    end
end
```
