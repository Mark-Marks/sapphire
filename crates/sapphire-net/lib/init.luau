--!strict
--!native
--!optimize 2

-- No idea why this is all in one file
-- Let's say it's a microoptimization
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local signal = require(script.Parent.signal)
local squash = require(script.Parent.squash)
local types = require(script.types)

local data_types = require(script.data_types)
local data_serdes: { [string]: () -> squash.SerDes<unknown> } = data_types.types :: any
local id_to_type_lookup: { [number]: string } = data_types.id_to_type
local type_to_id_lookup: { [string]: number } = data_types.type_to_id

local run_context: "server" | "client" = if RunService:IsServer() then "server" else "client"
local fresh_channel_size: number = 1024

type remotes = {
    reliable: RemoteEvent,
    unreliable: UnreliableRemoteEvent,
    storage: Folder,
}
local function setup_remotes(): remotes
    if run_context == "server" then
        local reliable = Instance.new("RemoteEvent")
        reliable.Name = "sapphire_net_reliable"
        reliable.Parent = ReplicatedStorage

        local unreliable = Instance.new("UnreliableRemoteEvent")
        unreliable.Name = "sapphire_net_unreliable"
        unreliable.Parent = ReplicatedStorage

        local storage = Instance.new("Folder")
        storage.Name = "sapphire_net_storage"
        storage.Parent = ReplicatedStorage

        return {
            reliable = reliable,
            unreliable = unreliable,
            storage = storage,
        }
    end

    return {
        reliable = ReplicatedStorage:WaitForChild("sapphire_net_reliable") :: RemoteEvent,
        unreliable = ReplicatedStorage:WaitForChild("sapphire_net_unreliable") :: UnreliableRemoteEvent,
        storage = ReplicatedStorage:WaitForChild("sapphire_net_storage") :: Folder,
    }
end

local _remotes = setup_remotes()
local reliable_remote = _remotes.reliable
local unreliable_remote = _remotes.unreliable
local net_storage = _remotes.storage

-- QUEUES, thank you to 1Axen and blink's polling system
-- A queue is basically just a linked list
type entry = {
    value: any,
    next: entry?,
}

type queue = {
    head: entry?,
    tail: entry?,
}

local function create_queue(): queue
    return {
        head = nil,
        tail = nil,
    }
end

local function pop(queue: queue): any
    local head = queue.head
    if head == nil then
        return
    end

    queue.head = head.next
    return head.value
end

local function push(queue: queue, value: any)
    local entry: entry = {
        value = value,
        next = nil,
    }

    if queue.tail ~= nil then
        queue.tail.next = entry
    end

    queue.tail = entry

    if queue.head == nil then
        queue.head = entry
    end
end

-- EVENT BATCHES

type reliability_type = "reliable" | "unreliable"

local reliable_incoming: { [number]: signal.Signal<any, Player?> } = table.create(fresh_channel_size)
local unreliable_incoming: { [number]: signal.Signal<any, Player?> } = table.create(fresh_channel_size)

local reliable_incoming_queue: { [number]: queue } = table.create(fresh_channel_size)
local unreliable_incoming_queue: { [number]: queue } = table.create(fresh_channel_size)

-- Only reliable events are batched, as unreliables have a size limit of ~900 bytes
local outgoing_client = squash.cursor(fresh_channel_size)
local outgoing_server: { [Player]: squash.Cursor } = {}

-- Serdes localizations

local _buffer_serdes = squash.buffer()
local buffer_ser = _buffer_serdes.ser

local _packet_id_serdes = squash.uint(2)
local packet_id_ser = _packet_id_serdes.ser
local packet_id_des = _packet_id_serdes.des

local _type_id_serdes = squash.uint(1)
local type_id_ser = _type_id_serdes.ser
local type_id_des = _type_id_serdes.des

-- DYNAMIC SERDES

-- !! unfortunately, squash treats cursors like a stack
-- this means that data has to be written backwards so it can be read normally;
-- instead of doing | type | | data | we have to do | data | | type |
-- also has to store the length of tables so the packet id serdes upvalues will be used

local function sum<T>(x: T): number
    local n = 0
    for _ in x :: any do
        n += 1
    end
    return n
end

local function dynamic_serialize(value: unknown, passed_cursor: squash.Cursor?): squash.Cursor
    local cursor = passed_cursor or squash.cursor(fresh_channel_size)
    if not passed_cursor then
        type_id_ser(cursor, type_to_id_lookup["EOF"])
    end

    local data_type = typeof(value)
    if data_type ~= "table" then
        data_serdes[data_type]().ser(cursor, value)
        type_id_ser(cursor, type_to_id_lookup[data_type])
        return cursor
    end

    for k, v in value :: { [unknown]: unknown } do
        dynamic_serialize(v, cursor)
        dynamic_serialize(k, cursor)
    end
    packet_id_ser(cursor, sum(value))
    type_id_ser(cursor, type_to_id_lookup["table"])

    return cursor
end

local function dynamic_deserialize(value: buffer, passed_cursor: squash.Cursor?): unknown
    local cursor = passed_cursor or squash.frombuffer(value)

    local data_type = id_to_type_lookup[type_id_des(cursor)]
    if data_type == "EOF" then
        return nil
    end
    if data_type ~= "table" then
        return data_serdes[data_type]().des(cursor)
    end

    local n = packet_id_des(cursor)

    local reconstructed = {}

    for _ = 1, n do
        local k = dynamic_deserialize(value, cursor)
        local v = dynamic_deserialize(value, cursor)
        reconstructed[k] = v
    end

    return reconstructed
end

-- SHARED

local function fire_client_reliable(player: Player, data: buffer)
    buffer_ser(outgoing_server[player], data)
end

local function fire_client_unreliable(player: Player, data: buffer)
    unreliable_remote:FireClient(player, data)
end

local function fire_server_reliable(data: buffer)
    buffer_ser(outgoing_client, data)
end

local function fire_server_unreliable(data: buffer)
    unreliable_remote:FireServer(data)
end

-- REPLICATED VALUES

type replicated_value = {
    _value: StringValue,
    _data: {},
    read: () -> {},
    write: ({}) -> (),
}

local existing_replicated_values: { [string]: replicated_value } = {}

local function create_replicated_value(value: StringValue): replicated_value
    local replicated_value = {}
    replicated_value._value = value
    replicated_value._data = {}

    function replicated_value.read(): {}
        return replicated_value._data
    end

    function replicated_value.write(data: {})
        assert(run_context == "server", "[sapphire-net] Cannot write to replicated value on client")
        replicated_value._data = data
        replicated_value._value.Value = HttpService:JSONEncode(data)
    end

    if run_context == "client" then
        replicated_value._data = table.freeze(HttpService:JSONDecode(value.Value))

        value.Changed:Connect(function(data)
            if not data then
                return
            end

            replicated_value._data = table.freeze(HttpService:JSONDecode(data))
        end)
    end

    return replicated_value
end

local function get_replicated_value(name: string): replicated_value
    if existing_replicated_values[name] then
        return existing_replicated_values[name]
    end

    if run_context == "client" then
        local value_instance = net_storage:WaitForChild(name) :: StringValue
        local value = create_replicated_value(value_instance)
        existing_replicated_values[name] = value
        return value
    end

    local value_instance = Instance.new("StringValue")
    value_instance.Name = name
    value_instance.Parent = net_storage

    local value = create_replicated_value(value_instance)
    existing_replicated_values[name] = value
    return value
end

-- NAMESPACES

local packet_ids: { [number]: any } = {}

local function set_packet_id(id: number, packet: any)
    packet_ids[id] = packet
end

local unique_id = 0

type namespace = {
    packets: { [string]: number },
}

local function create_namespace(name: string, input: () -> { [string]: any })
    local replicator = get_replicated_value(name)
    local packets: { [string]: (id: number) -> any } = input()

    local result = {}

    if run_context == "server" then
        local namespace = {
            packets = {},
        }

        for name, packet in packets do
            unique_id += 1
            namespace.packets[name] = unique_id
            result[name] = packet(unique_id)

            set_packet_id(unique_id, result[name])
        end

        replicator.write(namespace)
    elseif run_context == "client" then
        local namespace = replicator.read() :: namespace

        for name, packet in packets do
            result[name] = packet(namespace.packets[name])
            set_packet_id(namespace.packets[name], result[name])
        end
    end

    return result
end

-- DEFINED

local readers: { [number]: squash.SerDes<any> } = table.create(fresh_channel_size)

local function construct_defined(props: types.packet_props<any>, packet_id: number)
    local reliability_type = props.reliability_type
    local _serdes: squash.SerDes<any> = props.value
    local ser = _serdes.ser

    local fire_client: (player: Player, data: buffer) -> () = if reliability_type == "reliable"
        then fire_client_reliable
        else fire_client_unreliable
    local fire_server: (data: buffer) -> () = if reliability_type == "reliable"
        then fire_server_reliable
        else fire_server_unreliable

    local queue: queue = if reliability_type == "reliable"
        then reliable_incoming_queue[packet_id]
        else unreliable_incoming_queue[packet_id]

    local signal: signal.Signal<any> = if reliability_type == "reliable"
        then reliable_incoming[packet_id]
        else unreliable_incoming[packet_id]

    local exports = {}

    setmetatable(exports, {
        __index = function(index)
            if
                (
                    index == "send_to"
                    or index == "send_to_all_except"
                    or index == "send_to_all"
                    or index == "send_to_list"
                ) and run_context == "client"
            then
                error("You cannot use send_to, send_to_all_except, send_to_list or send_to_all on the client")
            elseif index == "send" and run_context == "server" then
                error("You cannot use send on the server")
            end
        end,
    })

    function exports.send(data: any)
        local cursor = squash.cursor(fresh_channel_size)
        ser(cursor, data)
        packet_id_ser(cursor, packet_id)
        fire_server(squash.tobuffer(cursor))
    end

    if run_context == "server" then
        function exports.send_to(player: Player, data: any)
            local cursor = squash.cursor(fresh_channel_size)
            ser(cursor, data)
            packet_id_ser(cursor, packet_id)
            fire_client(player, squash.tobuffer(cursor))
        end

        function exports.send_to_all_except(except: Player, data: any)
            local cursor = squash.cursor(fresh_channel_size)
            ser(cursor, data)
            packet_id_ser(cursor, packet_id)
            local buf = squash.tobuffer(cursor)
            for _, player in Players:GetPlayers() do
                if player == except then
                    continue
                end
                fire_client(player, buf)
            end
        end

        function exports.send_to_list(players: { Player }, data: any)
            local cursor = squash.cursor(fresh_channel_size)
            ser(cursor, data)
            packet_id_ser(cursor, packet_id)
            local buf = squash.tobuffer(cursor)
            for _, player in players do
                fire_client(player, buf)
            end
        end

        function exports.send_to_all(data: any)
            local cursor = squash.cursor(fresh_channel_size)
            ser(cursor, data)
            packet_id_ser(cursor, packet_id)
            local buf = squash.tobuffer(cursor)
            for _, player in Players:GetPlayers() do
                fire_client(player, buf)
            end
        end
    end

    function exports.next()
        local index = 0
        return function(): any
            index += 1
            local data = pop(queue)
            if data ~= nil then
                return index, data[1], data[2]
            end
            return
        end
    end

    function exports.listen(callback: (data: any, player: Player?) -> ()): () -> ()
        return signal:Connect(callback)
    end

    return exports
end

local function create_defined(props: types.packet_props<any>)
    props.reliability_type = props.reliability_type or "reliable"
    return function(packet_id: number)
        readers[packet_id] = props.value
        if props.reliability_type == "reliable" then
            reliable_incoming[packet_id] = signal()
            reliable_incoming_queue[packet_id] = create_queue()
        else
            unreliable_incoming[packet_id] = signal()
            unreliable_incoming_queue[packet_id] = create_queue()
        end
        return construct_defined(props, packet_id)
    end
end

-- UNDEFINED

type undefined_packets = { [string]: number }
local undefined_replicator = get_replicated_value("undefined_events")

local function construct_undefined(name: string, reliability_type: reliability_type, packet_id: number)
    local fire_client: (player: Player, data: buffer) -> () = if reliability_type == "reliable"
        then fire_client_reliable
        else fire_client_unreliable
    local fire_server: (data: buffer) -> () = if reliability_type == "reliable"
        then fire_server_reliable
        else fire_server_unreliable

    local queue: queue = if reliability_type == "reliable"
        then reliable_incoming_queue[packet_id]
        else unreliable_incoming_queue[packet_id]

    local signal: signal.Signal<any> = if reliability_type == "reliable"
        then reliable_incoming[packet_id]
        else unreliable_incoming[packet_id]

    local exports = {}

    setmetatable(exports, {
        __index = function(index)
            if
                (
                    index == "send_to"
                    or index == "send_to_all_except"
                    or index == "send_to_all"
                    or index == "send_to_list"
                ) and run_context == "client"
            then
                error("You cannot use send_to, send_to_all_except, send_to_list or send_to_all on the client")
            elseif index == "send" and run_context == "server" then
                error("You cannot use send on the server")
            end
        end,
    })

    function exports.send(data: any)
        local cursor = dynamic_serialize(data)
        packet_id_ser(cursor, packet_id)
        fire_server(squash.tobuffer(cursor))
    end

    if run_context == "server" then
        function exports.send_to(player: Player, data: any)
            local cursor = dynamic_serialize(data)
            packet_id_ser(cursor, packet_id)
            fire_client(player, squash.tobuffer(cursor))
        end

        function exports.send_to_all_except(except: Player, data: any)
            local cursor = dynamic_serialize(data)
            packet_id_ser(cursor, packet_id)
            local buf = squash.tobuffer(cursor)
            for _, player in Players:GetPlayers() do
                if player == except then
                    continue
                end
                fire_client(player, buf)
            end
        end

        function exports.send_to_list(players: { Player }, data: any)
            local cursor = dynamic_serialize(data)
            packet_id_ser(cursor, packet_id)
            local buf = squash.tobuffer(cursor)
            for _, player in players do
                fire_client(player, buf)
            end
        end

        function exports.send_to_all(data: any)
            local cursor = dynamic_serialize(data)
            packet_id_ser(cursor, packet_id)
            local buf = squash.tobuffer(cursor)
            for _, player in Players:GetPlayers() do
                fire_client(player, buf)
            end
        end
    end

    function exports.next()
        local index = 0
        return function(): any
            index += 1
            local data = pop(queue)
            if data ~= nil then
                return index, data[1], data[2]
            end
            return
        end
    end

    function exports.listen(callback: (data: any, player: Player?) -> ()): () -> ()
        return signal:Connect(callback)
    end

    return exports
end

local function create_undefined(name: string, reliability_type: reliability_type)
    local undefined_packets = undefined_replicator.read() :: undefined_packets

    unique_id += 1
    local packet_id = unique_id

    if run_context == "server" then
        undefined_packets[name] = packet_id
        undefined_replicator.write(undefined_packets)
    end
    readers[packet_id] = "dynamic" :: any

    if reliability_type == "reliable" then
        reliable_incoming[packet_id] = signal()
        reliable_incoming_queue[packet_id] = create_queue()
    else
        unreliable_incoming[packet_id] = signal()
        unreliable_incoming_queue[packet_id] = create_queue()
    end

    return construct_undefined(name, reliability_type, packet_id)
end

-- RUN CONTEXT SPECIFIC HANDLERS

local function extension()
    if run_context == "server" then
        local function player_added(player: Player)
            outgoing_server[player] = squash.cursor(fresh_channel_size)
        end

        local function player_removing(player: Player)
            outgoing_server[player] = nil
        end

        Players.PlayerAdded:Connect(player_added)
        Players.PlayerRemoving:Connect(player_removing)

        for _, player in Players:GetPlayers() do
            player_added(player)
        end

        local function replicate()
            for player, cursor in outgoing_server do
                if cursor.Pos <= 0 then
                    continue
                end

                print("sent to client")

                local buf = squash.tobuffer(cursor)
                reliable_remote:FireClient(player, buf)

                cursor = squash.cursor(fresh_channel_size)
            end
        end

        RunService.Heartbeat:Connect(replicate)

        reliable_remote.OnServerEvent:Connect(function(player, buf: buffer)
            if typeof(buf) ~= "buffer" then
                return
            end

            local cursor = squash.frombuffer(buf)
            local packet_id = packet_id_des(cursor)

            local reader = readers[packet_id]
            local signal = reliable_incoming[packet_id]
            local queue = reliable_incoming_queue[packet_id]
            if not reader or not signal or not queue then
                return
            end

            if reader == ("dynamic") :: any then
                local data = dynamic_deserialize(buf)
                signal:Fire(data, player)
                push(queue, { data, player })
                return
            end

            local data = reader.des(cursor)
            signal:Fire(data, player)
            push(queue, { data, player })
        end)

        unreliable_remote.OnServerEvent:Connect(function(player, buf: buffer)
            if typeof(buf) ~= "buffer" then
                return
            end

            local cursor = squash.frombuffer(buf)
            local packet_id = packet_id_des(cursor)

            local reader = readers[packet_id]
            local signal = unreliable_incoming[packet_id]
            local queue = unreliable_incoming_queue[packet_id]
            if not reader or not signal or not queue then
                return
            end

            if reader == ("dynamic") :: any then
                local data = dynamic_deserialize(buf)
                signal:Fire(data, player)
                push(queue, { data, player })
                return
            end

            local data = reader.des(cursor)
            signal:Fire(data, player)
            push(queue, { data, player })
        end)
    else
        local elapsed = 0
        local function replicate(delta_time: number)
            elapsed += delta_time
            if elapsed < (1 / 61) then
                return
            end
            elapsed -= (1 / 61)

            if outgoing_client.Pos <= 0 then
                return
            end

            local buf = squash.tobuffer(outgoing_client)
            reliable_remote:FireServer(buf)
            outgoing_client = squash.cursor(fresh_channel_size)
        end

        RunService.Heartbeat:Connect(replicate)

        reliable_remote.OnClientEvent:Connect(function(buf: buffer)
            local cursor = squash.frombuffer(buf)
            local packet_id = packet_id_des(cursor)

            local reader = readers[packet_id]
            local signal = reliable_incoming[packet_id]
            local queue = reliable_incoming_queue[packet_id]
            if not reader or not signal or not queue then
                return
            end

            if reader == ("dynamic") :: any then
                local data = dynamic_deserialize(buf)
                signal:Fire(data)
                push(queue, data)
                return
            end

            local data = reader.des(cursor)
            signal:Fire(data)
            push(queue, data)
        end)

        unreliable_remote.OnClientEvent:Connect(function(buf: buffer)
            local cursor = squash.frombuffer(buf)
            local packet_id = packet_id_des(cursor)

            local reader = readers[packet_id]
            local signal = unreliable_incoming[packet_id]
            local queue = unreliable_incoming_queue[packet_id]
            if not reader or not signal or not queue then
                return
            end

            if reader == ("dynamic") :: any then
                local data = dynamic_deserialize(buf)
                signal:Fire(data)
                push(queue, data)
                return
            end

            local data = reader.des(cursor)
            signal:Fire(data)
            push(queue, data)
        end)
    end
end

-- EXPORTS

export type packet_props<T> = types.packet_props<T>
export type relability_type = types.reliability_type
export type event<T> = types.event<T>
export type net = types.net

return (
    table.freeze({
        identifier = "sapphire-net",
        extension = extension,

        defined = create_defined,
        undefined = create_undefined,

        define_namespace = create_namespace,

        data_types = data_types.types,
    }) :: any
) :: types.net
