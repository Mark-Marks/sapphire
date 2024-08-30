--!strict
--!native
--!optimize 2

-- Big credits to ffrostfall/bytenet for a lot of useful code to make networking libraries like this work and be optimized

-- No idea why this is all in one file
-- Let's say it's a microoptimization
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local construct_signal = require(script.Parent.signal)
local squash = require(script.Parent.squash)
local types = require(script.types)

local data_types = require(script.data_types)
local data_serdes: { [string]: () -> squash.SerDes<unknown> } = data_types.types :: any

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

type channel = data_types.channel
local function create_channel()
    return data_types.channel(fresh_channel_size)
end

type reliability_type = "reliable" | "unreliable"

local incoming_signals: { [number]: construct_signal.Signal<any, Player?> } = table.create(fresh_channel_size)
local incoming_queue: { [number]: queue } = table.create(fresh_channel_size)

-- Only reliable events are batched, as unreliables have a size limit of ~900 bytes
local outgoing_client = create_channel()
local outgoing_server: { [Player]: channel } = {}

-- Serdes upvalue localizations

local _packet_id_serdes = squash.vlq() --squash.uint(2)
local packet_id_ser = _packet_id_serdes.ser
local packet_id_des = _packet_id_serdes.des

-- DYNAMIC SERDES

local dynamic_serdes = data_serdes.unknown()
local dynamic_ser = dynamic_serdes.ser

-- taken from squash, `tryRealloc`
-- you can't merge cursors
local function alloc(channel: channel, bytes: number)
    local b = channel.Buf
    local p = channel.Pos
    local len = buffer.len(b)
    if len < p + bytes then
        local exponent = math.ceil(math.log((bytes + p) / len, 1.5))
        local new = buffer.create(len * 1.5 ^ exponent)
        buffer.copy(new, 0, b, 0)
        channel.Buf = new
    end
end

local function dump_into_batch(channel: channel, data: buffer, refs: { Instance })
    local len = buffer.len(data)
    alloc(channel, len)
    buffer.copy(channel.Buf, channel.Pos, data, 0, len)
    channel.Pos += len
    for id, ref in refs do
        channel.references[id] = ref
    end
end

-- SHARED

local function fire_client_reliable(player: Player, data: buffer, refs: { Instance })
    if not outgoing_server[player] then
        outgoing_server[player] = create_channel()
    end
    dump_into_batch(outgoing_server[player], data, refs)
end

local function fire_client_unreliable(player: Player, data: buffer, refs: { Instance })
    unreliable_remote:FireClient(player, data, #refs > 0 and refs or nil)
end

local function fire_server_reliable(data: buffer, refs: { Instance })
    dump_into_batch(outgoing_client, data, refs)
end

local function fire_server_unreliable(data: buffer, refs: { Instance })
    unreliable_remote:FireServer(data, #refs > 0 and refs or nil)
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
    value.write({})
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

        for packet_name, packet in packets do
            unique_id += 1
            namespace.packets[packet_name] = unique_id
            result[packet_name] = packet(unique_id)

            set_packet_id(unique_id, result[packet_name])
        end

        replicator.write(namespace)
    elseif run_context == "client" then
        local namespace = replicator.read() :: namespace

        for packet_name, packet in packets do
            result[packet_name] = packet(namespace.packets[packet_name])
            set_packet_id(namespace.packets[packet_name], result[packet_name])
        end
    end

    return result
end

-- SHARED

local readers: { [number]: squash.SerDes<any> } = table.create(fresh_channel_size)

local function construct_event(
    reliability_type: reliability_type,
    packet_id: number,
    ser: (cursor: squash.Cursor, value: any) -> ()
)
    local fire_client: (player: Player, data: buffer, refs: { Instance }) -> () = if reliability_type == "reliable"
        then fire_client_reliable
        else fire_client_unreliable
    local fire_server: (data: buffer, refs: { Instance }) -> () = if reliability_type == "reliable"
        then fire_server_reliable
        else fire_server_unreliable

    local queue = incoming_queue[packet_id]
    local signal = incoming_signals[packet_id]

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
        local channel = create_channel()
        ser(channel, data)
        packet_id_ser(channel, packet_id)
        fire_server(squash.tobuffer(channel), channel.references)
    end

    if run_context == "server" then
        function exports.send_to(player: Player, data: any)
            local channel = create_channel()
            ser(channel, data)
            packet_id_ser(channel, packet_id)
            fire_client(player, squash.tobuffer(channel), channel.references)
        end

        function exports.send_to_all_except(except: Player, data: any)
            local channel = create_channel()
            ser(channel, data)
            packet_id_ser(channel, packet_id)
            local buf = squash.tobuffer(channel)
            for _, player in Players:GetPlayers() do
                if player == except then
                    continue
                end
                fire_client(player, buf, channel.references)
            end
        end

        function exports.send_to_list(players: { Player }, data: any)
            local channel = create_channel()
            ser(channel, data)
            packet_id_ser(channel, packet_id)
            local buf = squash.tobuffer(channel)
            for _, player in players do
                fire_client(player, buf, channel.references)
            end
        end

        function exports.send_to_all(data: any)
            local channel = create_channel()
            ser(channel, data)
            packet_id_ser(channel, packet_id)
            local buf = squash.tobuffer(channel)
            for _, player in Players:GetPlayers() do
                fire_client(player, buf, channel.references)
            end
        end
    end

    function exports.poll()
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

-- DEFINED

local function create_defined(props: types.packet_props<any>)
    props.reliability_type = props.reliability_type or "reliable"
    return function(packet_id: number)
        readers[packet_id] = props.value
        incoming_queue[packet_id] = create_queue()
        incoming_signals[packet_id] = construct_signal()
        return construct_event(props.reliability_type or "reliable", packet_id, props.value.ser)
    end
end

-- UNDEFINED

type undefined_packets = { [string]: number }
local undefined_replicator = get_replicated_value("undefined_events")

local function create_undefined(name: string, reliability_type: reliability_type)
    local undefined_packets = undefined_replicator.read() :: undefined_packets
    local packet_id = 0
    if undefined_packets[name] and run_context == "client" then
        packet_id = undefined_packets[name]
    else
        unique_id += 1
        packet_id = unique_id

        undefined_packets[name] = packet_id
        undefined_replicator.write(undefined_packets)
    end

    readers[packet_id] = dynamic_serdes

    incoming_queue[packet_id] = create_queue()
    incoming_signals[packet_id] = construct_signal()

    return construct_event(reliability_type, packet_id, dynamic_ser)
end

-- ENTRYPOINT

local function read(channel: channel, player: Player?)
    local packet_id = packet_id_des(channel)

    local reader = readers[packet_id]
    local queue = incoming_queue[packet_id]
    local signal = incoming_signals[packet_id]

    local data = reader.des(channel)
    signal:Fire(data, player)
    push(queue, { data, player })
end

local function count(x: {}): number
    local n = 0
    for _ in x do
        n += 1
    end
    return n
end

local function extension()
    if run_context == "server" then
        local function player_added(player: Player)
            if outgoing_server[player] then
                return
            end
            outgoing_server[player] = create_channel()
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
            for player, channel in outgoing_server do
                if channel.Pos <= 0 then
                    continue
                end

                local buf = squash.tobuffer(channel)
                reliable_remote:FireClient(
                    player,
                    buf,
                    if count(channel.references) > 0 then channel.references else nil
                )

                outgoing_server[player] = create_channel()
            end
        end

        RunService.Heartbeat:Connect(replicate)

        reliable_remote.OnServerEvent:Connect(function(player, buf: buffer, references: { Instance }?)
            if typeof(buf) ~= "buffer" then
                return
            end

            local channel = data_types.channel_from_buffer(buf)
            channel.references = if typeof(references) == "table" then references else nil :: any

            while channel.Pos > 0 do
                read(channel, player)
            end
        end)

        unreliable_remote.OnServerEvent:Connect(function(player, buf: buffer, references: { Instance }?)
            if typeof(buf) ~= "buffer" then
                return
            end

            local channel = data_types.channel_from_buffer(buf)
            channel.references = if typeof(references) == "table" then references else nil :: any
            read(channel, player)
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
            reliable_remote:FireServer(
                buf,
                if count(outgoing_client.references) > 0 then outgoing_client.references else nil
            )
            outgoing_client = create_channel()
        end

        RunService.Heartbeat:Connect(replicate)

        reliable_remote.OnClientEvent:Connect(function(buf: buffer, references: { Instance }?)
            local channel = data_types.channel_from_buffer(buf)
            channel.references = if typeof(references) == "table" then references else nil :: any

            while channel.Pos > 0 do
                read(channel)
            end
        end)

        unreliable_remote.OnClientEvent:Connect(function(buf: buffer, references: { Instance }?)
            local channel = data_types.channel_from_buffer(buf)
            channel.references = if typeof(references) == "table" then references else nil :: any
            read(channel)
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
        _data_types = data_types,
    }) :: any
) :: types.net
