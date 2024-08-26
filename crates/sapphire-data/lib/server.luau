--!strict
local Players = game:GetService("Players")

local delta_compress = require(script.Parent.Parent.delta_compress)
local keyform = require(script.Parent.Parent.keyform)
local signal = require(script.Parent.Parent.signal)

local util = require(script.Parent.util)

type key<T> = keyform.key<T>

--- Creates a sever wrapper around [ffrostfall/keyForm](https://github.com/ffrostfall/keyForm).
--- ```luau
--- -- src/server/data.luau
--- local sapphire_data = require("@pkg/sapphire_data")
---
--- local template = {
---     ...
--- }
--- export type data = typeof(template)
---
--- return sapphire_data.server({
---     store_name = "data",
--      template = template,
--- })
--- ```
--- ```luau
--- -- src/server/main.server.luau
--- local data = require("@server/data")
--- ...
--- sapphire
---     :use(data)
--- ```
--- ```luau
--- -- src/server/services/data_consumer.luau
--- local data = require("@server/data")
--- -- do stuff on player data!
--- ```
export type server<data> = {
    --- @private
    --- Required by `sapphire:use()`
    identifier: string,
    --- @private
    --- Required by `sapphire:use()`
    extension: () -> (),
    --- @private
    --- Required by `sapphire:use()`
    methods: {},

    --- Gets the players data.
    --- @param player Player
    --- @return data
    get_data: (player: Player) -> data,
    --- Listens to data changes. Returns a disconnect function.
    --- @param fn (Player, data) -> ()
    --- @return () -> () -- Disconnect
    on_data_changed: (fn: (Player, data) -> ()) -> () -> (),
    --- Creates a transform for player data.
    --- Use `sapphire_data.transform()` for one time data changes.
    --- ```luau
    --- local increment_coins = sapphire_data.create_transform(function(data, n: number)
    ---     data.coins += n
    ---     return data
    --- end)
    --- increment_coins(player, 10)
    --- ```
    --- @param fn (data, T...) -> data
    --- @return (Player, T...) -> ()
    create_transform: <T...>(fn: (data, T...) -> data) -> (Player, T...) -> (),
    --- Transforms player data with the given function.
    --- Use `sapphire_data.create_transform()` for multiple data changes.
    --- ```luau
    --- sapphire_data.transform(player, function(data)
    ---     data.coins += 10
    ---     return data
    --- end)
    --- ```
    --- @param player Player
    --- @param fn (data) -> data
    transform: (player: Player, fn: (data) -> data) -> (),
    --- Calculates the difference between the player's last calculated difference and their current data.
    --- Returns a buffer representing the difference.
    --- ```luau
    --- local difference = sapphire_data.calculate_difference(player)
    --- if not difference then
    ---     return
    --- end
    --- data_replication_event.send_to(player, difference)
    --- ```
    --- You may also provide the new data yourself to expose only what you need to to the client.
    --- ```luau
    --- local exposed_data = make_exposable(sapphire_data.get_data(player))
    --- local difference = sapphire_data.calculate_difference(player, exposed_data)
    --- if not difference then
    ---     return
    --- end
    --- data_replication_event.send_to(player, difference)
    --- ```
    --- @param player Player
    --- @return buffer?
    calculate_difference: (player: Player, exposable_data: any) -> buffer?,
}

export type settings<data> = {
    --- Store name.
    store_name: string,
    --- Player data template.\
    --- ⚠️ Expected to be a table!
    template: data,
}
return function<data>(settings: settings<data>): server<data>
    local store = keyform.createStore(settings.store_name, settings.template)

    local last_difference: { [Player]: any? } = {}
    local keys: { [Player]: key<data> } = {}
    local on_data_changed: signal.Signal<Player, data> = signal()

    -- Data reconcilation in keyform v0.2.2 doesn't work for some reason. This is a fix to it
    local reconcile_data = store:createTransform(function(data, template: data)
        data = util.reconcile(data :: any, template :: any)
        return data
    end)

    local transform_data = store:createTransform(
        function(data, player: Player, transform: (data: data) -> data, fire_changed: (Player, data) -> ())
            local new_data = transform(data)
            fire_changed(player, new_data)
            return new_data
        end
    )

    local SapphireData = {} :: server<data>
    SapphireData.identifier = "sapphire-data"
    SapphireData.methods = {}

    function SapphireData.extension()
        Players.PlayerAdded:Connect(function(player)
            local key = store:loadKey(`player_{player.UserId}`)
            keys[player] = key

            local ok = key:lockAsync()
            if ok then
                reconcile_data(key, settings.template)
                on_data_changed:Fire(player, key:read())
                return
            end

            player:Kick("Session locked")
        end)

        Players.PlayerRemoving:Connect(function(player)
            if keys[player] then
                keys[player]:unlock()
                keys[player]:remove()
            end
        end)
    end

    function SapphireData.get_data(player: Player): data
        return keys[player]:read()
    end

    function SapphireData.on_data_changed(fn: (Player, data) -> ()): () -> ()
        return on_data_changed:Connect(fn)
    end

    function SapphireData.create_transform<T...>(fn: (data, T...) -> data)
        local transform = store:createTransform(function(data, player, ...)
            local new = fn(data, ...)
            on_data_changed:Fire(player, data)
            return new
        end)

        return function(player, ...)
            transform(keys[player], player, ...)
        end
    end

    local function fire_changed(player: Player, data: data)
        on_data_changed:Fire(player, data)
    end

    function SapphireData.transform(player: Player, fn: (data) -> data)
        transform_data(keys[player], player, fn, fire_changed)
    end

    function SapphireData.calculate_difference(player: Player, exposable_data: any?): buffer?
        local data = if exposable_data ~= nil then exposable_data else keys[player]:read()
        local last = last_difference[player]
        last_difference[player] = data

        if not last then
            return delta_compress.diffImmutable(nil, data)
        end

        return delta_compress.diffImmutable(last, data)
    end

    return SapphireData
end
