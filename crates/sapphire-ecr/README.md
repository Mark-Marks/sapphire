# sapphire-ecr
A lightweight scheduler + niceties (replication, etc.) for [centau/ecr](https://github.com/centau/ecr) for [Mark-Marks/sapphire](https://github.com/Mark-Marks/sapphire)

# Installation
1. Install it with wally
```toml
[dependencies]
sapphire_ecr = "mark-marks/sapphire-ecr@LATEST" # replace LATEST with the latest version
```
2. `wally install`
3. Extend sapphire with it
```luau
local sapphire_ecr = require("@pkg/sapphire_ecr")

sapphire
    :use(sapphire_ecr)
```

# API

## Exports

### .registry
```luau
type registry = ecr.Registry
```

### .stepped_systems
Readonly!
```luau
type stepped_systems = { system }
```

### .heartbeat_systems
Readonly!
```luau
type heartbeat_systems = { system }
```

### .render_stepped_systems
Readonly!
```luau
type render_stepped_systems = { system }
```

### .ecr
Reexport of ecr
```luau
SapphireEcr.ecr = ecr
```

## Types

### loop_type
```luau
type loop_type = "Stepped" | "Heartbeat" | "RenderStepped"
```

### system
```luau
type system = {
    --- Fires every `RunService.Stepped`
    runner: (delta_time: number) -> (),
    --- 1 = lowest priority
    priority: number?,
    --- Defaults to "Stepped"
    loop_type: loop_type?,
}
```

### spawner<T...>
```luau
type spawner<T...> = {
    spawn: (T...) -> ecr.entity,
    spawn_with_handle: (T...) -> ecr.Handle,
}
```

### raw_data
`map<component_id, map<entity_id, component_value>>`
Migrated from `map<entity_id, map<component_id, component_value>>` to do SoA instead of AoS
```luau
type raw_data = {
    [number]: { [ecr.entity]: unknown },
}
```

### replicator
```luau
type replicator = {
    get_full_data: () -> raw_data,
    calculate_difference: () -> raw_data?,
    apply_difference: (difference: raw_data) -> (),
}
```

### entity
```luau
type entity = ecr.entity
```

### Signal<T...>
```luau
type Signal<T...> = ecr.Signal<T...>
```

### Connection
```luau
type Connection = ecr.Connection
```

### Handle
```luau
type Handle = ecr.Handle
```

### View<T...>
```luau
type View<T...> = ecr.View<T...>
```

### Observer<T...>
```luau
type Observer<T...> = ecr.Observer<T...>
```

### Group<T...>
```luau
type Group<T...> = ecr.Group<T...>
```

### Registry
```luau
type Registry = ecr.Registry
```

### Queue<T...>
```luau
type Queue<T...> = ecr.Queue<T...>
```

## Registered methods

### .system()
Registers a system.
```luau
(
    singleton: sapphire.singleton
)
```
Singletons need to follow the following format:
```luau
type format = {
    system: (registry: ecr.Registry) -> (delta_time: number) -> (),
    --- Defaults to 1
    priority: number?,
    --- Defaults to `Stepped`
    loop_type: loop_type?,
}
```
Systems on the server that use `RenderStepped` will be migrated to `Heartbeat`.

## Functions

### .spawn_entity()
Creates an entity and returns its id.
```luau
() -> ecr.entity
```

### .spawn_entity_with_handle()
Creates an entity and returns a handle to it.
```luau
() -> ecr.Handle
```

### .create_spawner()
Creates a spawner.
```luau
<T...>(
    ...: T...
) -> spawner<T...>
```
```luau
local spawner = sapphire_ecr.create_spawner(components.part, components.velocity, components.position)
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
on which the difference is then applied to the registry.\
Albeit it's called a replicator, it doesn't replicate the data by itself.
It allows the developer to use any networking libary to replicate the changes.
```luau
-- server
local replicator = sapphire_ecr.create_replicator(component_a, component_b, ...)

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
local replicator = sapphire_ecr.create_replicator(component_a, component_b, ...)

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
) -> ecr.entity
```

### .spawn_with_handle()
Creates an entity with the given components and returns a handle to it.
```luau
(
    T...
) -> ecr.Handle
```

## replicator
A replicator keeps track of all entities with the passed components and their values -
whenever a component is changed (add, change, remove) and the replicator listens to it, it's also changed within the contained raw data.\
The developer can then calculate the difference on the server and send it to the client every time,
on which the difference is then applied to the registry.\
Albeit it's called a replicator, it doesn't replicate the data by itself.
It allows the developer to use any networking libary to replicate the changes.
```luau
-- server
local replicator = sapphire_ecr.create_replicator(component_a, component_b, ...)

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
local replicator = sapphire_ecr.create_replicator(component_a, component_b, ...)

function singleton.system()
    return function()
        for _, difference in data_replication_event.poll() do
            replicator.apply_difference(difference)
        end
    end
end
```

### .get_full_data()
Gets the full data representing the entire registry.
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
() -> raw_data?
```
```luau
local replicator = sapphire_ecr.create_replicator(component_a, component_b, ...)

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
    difference: raw_data
) -> ()
```
```luau
local replicator = sapphire_ecr.create_replicator(component_a, component_b, ...)

function singleton.system()
    return function()
        for _, difference in data_replication_event.poll()
            replicator.apply_difference(difference)
        end
    end
end
```
