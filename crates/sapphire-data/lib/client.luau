--!strict
local delta_compress = require(script.Parent.Parent.delta_compress)
local signal = require(script.Parent.Parent.signal)

local util = require(script.Parent.util)

--- Creates a client wrapper around [ffrostfall/keyForm](https://github.com/ffrostfall/keyForm).
--- ```luau
--- -- src/client/data.luau
--- local sapphire_data = require("@pkg/sapphire_data")
---
--- local template = {
---     ...
--- }
--- export type data = typeof(template)
---
--- return sapphire_data.client({
--      template = template,
--- })
--- ```
--- ```luau
--- -- src/client/main.client.luau
--- local data = require("@client/data")
--- ...
--- sapphire
---     :use(data)
--- ```
--- ```luau
--- -- src/client/controllers/data_consumer.luau
--- local data = require("@client/data")
--- -- do stuff on your data!
--- ```
export type client<data> = {
    --- @private
    --- Required by `sapphire:use()`
    identifier: string,
    --- @private
    --- Required by `sapphire:use()`
    extension: () -> (),
    --- @private
    --- Required by `sapphire:use()`
    methods: {},

    --- Gets the local players data.
    --- @return data?
    get_data: () -> data?,
    --- Applies the difference received from the server's `sapphire_data.calculate_difference()`.
    --- ```luau
    --- data_replication_event.listen(function(difference)
    ---     sapphire_data.apply_difference(difference)
    --- end)
    --- ```
    --- @param difference buffer
    apply_difference: (difference: buffer) -> (),
    --- Listens to data changes. The received data is guaranteed to not be nil.\
    --- Returns a disconnect function.
    --- @param fn (data) -> ()
    --- @return () -> () -- Disconnect
    on_data_changed: (fn: (data) -> ()) -> () -> (),
}

export type settings<data> = {
    --- Player data template.\
    --- ⚠️ Expected to be a table!
    template: data,
}
return function<data>(settings: settings<data>): client<data>
    local data: data? = nil
    local on_data_changed: signal.Signal<data> = signal()

    local SapphireData = {} :: client<data>
    SapphireData.identifier = "sapphire-data"
    SapphireData.methods = {}

    function SapphireData.extension() end

    function SapphireData.get_data(): data?
        return data
    end

    function SapphireData.apply_difference(difference: buffer)
        local new = delta_compress.applyImmutable(data, difference)
        data = util.deep_freeze(new)
        on_data_changed:Fire(data :: any)
    end

    function SapphireData.on_data_changed(fn: (data) -> ()): () -> ()
        return on_data_changed:Connect(fn)
    end

    return SapphireData
end
