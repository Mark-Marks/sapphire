# sapphire-net
A networking library for [Mark-Marks/sapphire](https://github.com/Mark-Marks/sapphire).

Utilizes [Data-Oriented-House/Squash](https://github.com/Data-Oriented-House/Squash) for buffer serdes.

Features both defined and undefined events:
```luau
-- shared/events.luau
local t = net.data_types
return net.define_namespace("namespace_name", function()
    return {
        event_name = net.defined({
            -- `value` can be any type, but it's a struct for demonstration purposes
            value = t.struct({
                a = t.string(),
                b = t.uint(2), -- in bytes
            }),
        }),
        -- etc.
    }
end)
```
```luau
-- singletons/singleton.luau
-- Dynamically serializes and deserializes data into a buffer.
-- A bit less performant and way less bandwidth efficient (but still more than regularly sending data)
-- because the information of what type and what length something is needs to be stored.
local undefined_event: net.event<{ name: string, age: number }> = net.undefined("event_name", "reliable")
```

# Benchmarks:
WIP
