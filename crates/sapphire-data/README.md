# sapphire-data
A lightweight wrapper around [ffrostfall/keyForm](https://github.com/ffrostfall/keyForm) for [Mark-Marks/sapphire](https://github.com/Mark-Marks/sapphire)

# Installation
1. Install it with wally
```toml
[dependencies]
sapphire_data = "mark-marks/sapphire-data@LATEST" # replace LATEST with the latest version
```
`wally install`
2. Set it up
```luau
local sapphire_data = require("@pkg/sapphire_data")

local template = {
    ...
}
export type data = typeof(template)

return sapphire_data.server({
    store_name = "data",
    template = template,
})
-- or on the client:
return sapphire_data.client({
    template = template,
})
```
3. Extend sapphire with it
```luau
local data = require(".../data")

sapphire
    :use(data)
```

# API

## Types

### server<data>
```luau
type server<data> = {
    --- @private
    identifier: string,
    --- @private
    extension: () -> (),
    --- @private
    methods: {},

    get_data: (player: Player) -> data,
    on_data_changed: (fn: (Player, data) -> ()) -> () -> (),
    create_transform: <T...>(fn: (data, T...) -> data) -> (Player, T...) -> (),
    transform: (player: Player, fn: (data) -> data) -> (),
    calculate_difference: (player: Player, exposable_data: any) -> buffer?,
}
```

### server_settings<data>
```luau
type server_settings<data> = {
    --- Store name.
    store_name: string,
    --- Player data template.
    --- ⚠️ Expected to be a table!
    template: data,
}
```

### client<data>
```luau
type client<data> = {
    --- @private
    identifier: string,
    --- @private
    extension: () -> (),
    --- @private
    methods: {},

    get_data: () -> data?,
    apply_difference: (difference: buffer) -> (),
    on_data_changed: (fn: (data) -> ()) -> () -> (),
}
```

### client_settings<data>
```luau
type client_settings<data> = {
    --- Player data template.
    --- ⚠️ Expected to be a table!
    template: data,
}
```

## Registered methods

## Functions

### .server()
```luau
<data>(
    settings: server_settings<data>
) -> server<data>
```

### .client()
```luau
<data>(
    settings: client_settings<data>
) -> client<data>
```

## server<data>

### .get_data()
Gets the players data.
```luau
(
    player: Player
) -> data
```

### .on_data_changed()
Listens to data changes. Returns a disconnect function.
```luau
(
    fn: (Player, data) -> ()
) -> () -> ()
```

### .create_transform()
Creates a transform for player data.
Use `sapphire_data.transform()` for one time data changes.
```luau
<T...>(
    fn: (data, T...) -> data
) -> (
    player: Player,
    T...
) -> ()
```
```luau
local increment_coins = sapphire_data.create_transform(function(data, n: number)
    data.coins += n
    return data
end)
increment_coins(player, 10)
```

### .transform()
Transforms player data with the given function.
Use `.create_transform()` for multiple data changes.
```luau
(
    player: Player
) -> (
    data: data
) -> data
```
```luau
sapphire_data.transform(player, function(data)
    data.coins += 10
    return data
end)
```

### .calculate_difference()
Calculates the difference between the player's last calculated difference and their current data.
Returns a buffer representing the difference.
```luau
(
    player: Player,
    exposable_data: any
) -> buffer?
```
```luau
local difference = sapphire_data.calculate_difference(player)
if not difference then
    return
end
data_replication_event.send_to(player, difference)
```
You may also provide the new data yourself to expose only what you need to to the client.
```luau
local exposed_data = make_exposable(sapphire_data.get_data(player))
local difference = sapphire_data.calculate_difference(player, exposed_data)
if not difference then
    return
end
data_replication_event.send_to(player, difference)
```

## client<data>

### .get_data()
Gets the local players data.
```luau
() -> data?
```

### .apply_difference()
Applies the difference received from the server's `sapphire_data.calculate_difference()`.
```luau
(
    difference: buffer
) -> ()
```
```luau
data_replication_event.listen(function(difference)
    sapphire_data.apply_difference(difference)
end)
```

### .on_data_changed()
Listens to data changes. The received data is guaranteed to not be nil.
Returns a disconnect function.
```luau
(
    fn: (data) -> ()
) -> () -> ()
