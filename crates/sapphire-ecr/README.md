# sapphire-ecr
A lightweight scheduler + niceties (replication, etc.) for [centau/ecr](https://github.com/centau/ecr) for [Mark-Marks/sapphire](https://github.com/Mark-Marks/sapphire)

# TODO
- [x] Write scheduler
- [ ] Add replication -- waiting for `sapphire-net`

# Installation
1. Install it with wally
- ```toml
[dependencies]
sapphire_ecr = "mark-marks/sapphire-ecr@LATEST" # replace LATEST with the latest version
```
- `wally install`
2. Extend sapphire with it
```luau
local sapphire_ecr = require("@packages/sapphire_ecr")

sapphire
    :use(sapphire_ecr)
```

# API

## Types

### LoopType
```luau
type LoopType = "Stepped" | "Heartbeat" | "RenderStepped"
```

### System
```luau
type System = {
    --- Fires every `RunService.Stepped`
    runner: (delta_time: number) -> (),
    --- 1 = lowest priority
    priority: number?,
    --- Defaults to "Stepped"
    loop_type: LoopType?,
}
```

### singleton
```luau
export type singleton = sapphire.singleton & {
    system: (registry: ecr.Registry) -> (delta_time: number) -> (),
    priority: number?,
    loop_type: LoopType?,
}
```

### Spawner<T...>
```luau
export type Spawner<T...> = {
    --- Creates an entity with the given components.
    --- @param ... T...
    --- @return ecr.entity
    spawn: (T...) -> ecr.entity,
    --- Creates an entity with the given components and returns a handle to it.
    --- @param ... T...
    --- @return ecr.Handle
    spawn_with_handle: (T...) -> ecr.Handle,
}
```

## Registered methods

### singleton.system()
```luau
(
    singleton: sapphire.Singleton & { system: (registry: ecr.Registry) -> (delta_time:number) -> () }
) -> void
```
```luau
function singleton.system(registry: ecr.Registry)
    return function(delta_time: number)
        -- loop code
    end
end
```

## Functions

### .create_spawner
```luau
<T...>(
    ...: T...
) -> Spawner<T...>
```

### .spawn_entity
```luau
() -> ecr.entity
```

### .spawn_entity_with_handle
```luau
() -> ecr.Handle
```
