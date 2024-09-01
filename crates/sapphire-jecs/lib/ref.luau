--!strict
local signal = require(script.Parent.Parent.signal)
--- Fires whenever a reference with a given key creates a new entity.
--- Useful to track freshly replicated entities.
--- @type signal<<number> entity, <any> key>
local on_created: signal.Signal<number, any> = signal()

local world = require(script.Parent.world)
local handle = require(script.Parent.handle)
local refs = {}

--- Gets an entity the given key references to.
--- If the key is nil, an entirely new entity is created and returned.
--- If the key doesn't reference an entity, a new entity is made for it to reference and returned.
--- @param key any
--- @return handle
local function ref(key: any): handle.handle
    if not key then
        return handle.new(world:entity())
    end

    local entity = refs[key]
    if not entity then
        entity = world:entity()
        refs[key] = entity
        on_created:Fire(entity, key)
    end

    return handle.new(entity)
end

return {
    ref = ref,
    on_created = on_created,
}
