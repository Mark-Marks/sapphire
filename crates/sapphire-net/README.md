# sapphire-net
A networking library for [Mark-Marks/sapphire](https://github.com/Mark-Marks/sapphire).

Utilizes [Data-Oriented-House/Squash](https://github.com/Data-Oriented-House/Squash) for buffer serdes.

Features both defined and undefined events:
```luau
-- shared/events.luau
-- Serializes and deserializes data into a buffer based on a pre defined structure.
local defined_event = net.defined.reliable_event({
    name = net.types.string(20), -- TWENTYCHARACTERSONLY
    age = net.types.number(4), -- squash supports 4 or 8 bytes, good enough
}) --> net.defined_event<{ name: string, age: number }>

return {
    defined_event = defined_event,
}
```
```luau
-- singletons/singleton.luau
-- Dynamically serializes and deserializes data into a buffer.
-- A bit less performant and way less bandwidth efficient (but still more than regularly sending data)
-- because the information of what type and what length something is needs to be stored.
local undefined_event: net.undefined_event<{ name: string, age: number }> = net.undefined.reliable_event()
```
