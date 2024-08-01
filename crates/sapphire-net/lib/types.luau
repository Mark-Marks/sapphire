export type event<T> = {
    --- Sends the data to the server. Client only - throws on the server.
    --- @param data T
    send: (data: T) -> (),

    --- Sends the data to the passed player. Server only - throws on the client.
    --- @param player Player
    --- @param data T
    send_to: (player: Player, data: T) -> (),
    --- Sends the data to all players except the passed player. Server only - throws on the client.
    --- @param player Player
    --- @param data T
    send_to_all_except: (player: Player, data: T) -> (),
    --- Sends the data to a list of players. Server only - throws on the client.
    --- @param players { Player }
    --- @param data T
    send_to_list: (players: { Player }, data: T) -> (),
    --- Sends the data to all players. Server only - throws on the client.
    --- @param data T
    send_to_all: (data: T) -> (),

    --- Received data is instantly fired through a signal, and is also stored in a queue.
    --- This function returns an iterator for all packets of data stored in the queue.
    --- Once a packet of data is iterated over, it's deleted from the queue.
    --- ```luau
    --- -- `player` is only featured on the server
    --- for index, data, player in event.next() do
    ---     ...
    ---     -- the current index is now removed from the queue as it was iterated over; you can only poll in one place
    --- end
    --- ```
    --- @return () -> (number index, T data, Player? player) -- Iterator
    next: () -> () -> (number, T, Player?),
    --- Connects the passed listener to the given event's signal.
    --- @param listener (data: T, player: Player?) -> () -- Listener. The player argument is only passed on the server.
    --- @return () -> () -- Disconnect function
    listen: (listener: (data: T, player: Player?) -> ()) -> () -> (),
}

export type reliability_type = "reliable" | "unreliable"

export type packet_props<T> = {
    value: T,
    reliability_type: reliability_type?,
}

export type net = {
    --- @private
    --- Required by `sapphire:use()`
    identifier: string,
    --- @private
    --- Required by `sapphire:use()`
    extension: () -> (),
    --- @private
    --- Required by `sapphire:use()`
    methods: {},

    defined: <T>(props: packet_props<T>) -> event<T>,
    undefined: <T>(name: string, reliability_type: reliability_type) -> event<T>,

    define_namespace: <T>(name: string, namespace: () -> T) -> T,

    data_types: {
        boolean: () -> boolean,
        --- Accuracy dimnishes using 7 or 8 bytes.
        uint: (bytes: number) -> number,
        --- Accuracy dimnishes using 7 or 8 byets.
        int: (bytes: number) -> number,
        --- Only supports 4 or 8 byets.
        number: (bytes: number?) -> number,
        string: (length: number?) -> string,
        buffer: (length: number?) -> buffer,
        vlq: () -> number,
        opt: <T>(serdes: T) -> T?,
        array: <T>(serdes: T, length: number?) -> { T },
        tuple: <T...>(T...) -> T...,
        record: <T>(schema: T) -> T,
        map: <K, V>(key_serdes: K, value_serdes: V) -> { [K]: V },
        table: (schema: { [string]: any }) -> { [string]: any },
        Axes: () -> Axes,
        BrickColor: () -> BrickColor,
        EnumItem: (enum: Enum) -> EnumItem,
        CatalogueSearchParams: () -> CatalogSearchParams,
        CFrame: (numer_serdes: number?) -> CFrame,
        Color3: () -> Color3,
        ColorSequenceKeypoint: () -> ColorSequenceKeypoint,
        ColorSequence: () -> ColorSequence,
        DateTime: () -> DateTime,
        Faces: () -> Faces,
        FloatCurveKey: () -> FloatCurveKey,
        Font: () -> Font,
        NumberRange: (number_serdes: number?) -> NumberRange,
        NumberSequenceKeypoint: (number_serdes: number?) -> NumberSequenceKeypoint,
        NumberSequence: (number_serdes: number?) -> NumberSequence,
        OverlapParams: () -> OverlapParams,
        RaycastParams: () -> RaycastParams,
        Vector3: (number_serdes: number?) -> Vector3,
        PathWaypoint: (number_serdes: number?) -> PathWaypoint,
        PhysicalProperties: () -> PhysicalProperties,
        Ray: (number_serdes: number?) -> Ray,
        RaycastResult: (number_serdes: number?) -> RaycastResult,
        Vector2: (number_serdes: number?) -> Vector2,
        Rect: (number_serdes: number?) -> Rect,
        Region3: (number_serdes: number?) -> Region3,
        Region3int16: (number_serdes: number?) -> Region3int16,
        RotationCurveKey: (number_serdes: number?) -> RotationCurveKey,
        TweenInfo: () -> TweenInfo,
        UDim: (number_serdes: number?) -> UDim,
        UDim2: (number_serdes: number?) -> UDim2,
        Vector2int16: () -> Vector2int16,
        Vector3int16: () -> Vector3int16,
    },
}

return "types"
