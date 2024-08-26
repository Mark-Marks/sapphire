--!strict
--!native
--!optimize 2
local squash = require(script.Parent.Parent.squash)
local exports: any

export type channel = squash.Cursor & {
    references: { Instance },
}

export type serdes<T> = {
    ser: (channel: channel, value: T) -> (),
    des: (channel: channel) -> T,
}

local function sum<T>(x: T): number
    local n = 0
    for _ in x :: any do
        n += 1
    end
    return n
end

local function write_reference(references: { Instance }, instance: Instance): number
    local id = #references + 1
    references[id] = instance
    return id
end

local _vlq_serdes = squash.vlq()
local vlq_ser = _vlq_serdes.ser
local vlq_des = _vlq_serdes.des

local instance_cache = {
    ser = function(channel: channel, value: Instance)
        local ref = write_reference(channel.references, value)
        vlq_ser(channel, ref)
    end,
    des = function(channel: channel): Instance?
        local refs = channel.references
        if not refs then
            return nil
        end

        local id = vlq_des(channel)
        local ref = refs[id]

        if typeof(ref) == "Instance" then
            return ref
        end
        return nil
    end,
}

local function instance_serdes(): serdes<Instance?>
    return instance_cache :: any
end

local nil_cache: serdes<nil> = {
    ser = function() end,
    des = function(): nil
        return nil
    end,
}

local function nil_serdes(): serdes<nil>
    return nil_cache
end

local _u8_serdes = squash.uint(1)
local u8_ser = _u8_serdes.ser
local u8_des = _u8_serdes.des

-- !! unfortunately, squash treats cursors like a stack
-- this means that data has to be written backwards so it can be read normally;
-- instead of doing | type | | data | we have to do | data | | type |
-- also has to store the length of tables so the packet id serdes upvalues will be used

local function unknown_serialize(channel: channel, value: unknown)
    local type_to_id_lookup = exports.type_to_id
    local data_serdes = exports.types

    local data_type = typeof(value)
    if data_type ~= "table" then
        data_serdes[data_type]().ser(channel, value)
        u8_ser(channel, type_to_id_lookup[data_type])
        return
    end

    for k, v in value :: { [unknown]: unknown } do
        unknown_serialize(channel, v)
        unknown_serialize(channel, k)
    end
    vlq_ser(channel, sum(value))
    u8_ser(channel, type_to_id_lookup["table"])
end

local function unknown_deserialize(channel: channel): unknown
    local id_to_type_lookup = exports.id_to_type
    local data_serdes = exports.types

    local data_type = id_to_type_lookup[u8_des(channel)]
    if data_type == nil then
        return nil
    end
    if data_type ~= "table" then
        return data_serdes[data_type]().des(channel)
    end

    local n = vlq_des(channel)

    local reconstructed = {}

    for _ = 1, n do
        local k = unknown_deserialize(channel)
        local v = unknown_deserialize(channel)
        reconstructed[k] = v
    end

    return reconstructed
end

local unknown_cache = {
    ser = unknown_serialize,
    des = unknown_deserialize,
}

local function unknown_serdes(): serdes<unknown>
    return unknown_cache
end

local function create_channel(size: number): channel
    return {
        Buf = buffer.create(size),
        Pos = 0,
        references = {},
    }
end

local function create_channel_from_buffer(buf: buffer): channel
    local cursor = squash.frombuffer(buf)
    return {
        Buf = cursor.Buf,
        Pos = cursor.Pos,
        references = {},
    }
end

exports = table.freeze({
    types = table.freeze({
        boolean = squash.boolean,
        uint = squash.uint,
        int = squash.int,
        number = function(bytes: number?): squash.SerDes<number>
            return squash.number(bytes or 4)
        end,
        string = squash.string,
        buffer = squash.buffer,
        vlq = squash.vlq,
        opt = squash.opt,
        array = squash.array,
        tuple = squash.tuple,
        record = squash.record,
        map = squash.map,
        table = squash.table,
        Axes = squash.Axes,
        BrickColor = squash.BrickColor,
        EnumItem = squash.EnumItem,
        CatalogueSearchParams = squash.CatalogueSearchParams,
        CFrame = function(number_serdes: squash.SerDes<number>?): squash.SerDes<CFrame>
            return squash.CFrame(number_serdes or squash.number(4))
        end,
        Color3 = squash.Color3,
        ColorSequenceKeypoint = squash.ColorSequenceKeypoint,
        ColorSequence = squash.ColorSequence,
        DateTime = squash.DateTime,
        Faces = squash.Faces,
        FloatCurveKey = squash.FloatCurveKey,
        Font = squash.Font,
        NumberRange = function(number_serdes: squash.SerDes<number>?): squash.SerDes<NumberRange>
            return squash.NumberRange(number_serdes or squash.number(4))
        end,
        NumberSequenceKeypoint = function(number_serdes: squash.SerDes<number>?): squash.SerDes<NumberSequenceKeypoint>
            return squash.NumberSequenceKeypoint(number_serdes or squash.number(4))
        end,
        NumberSequence = function(number_serdes: squash.SerDes<number>?): squash.SerDes<NumberSequence>
            return squash.NumberSequence(number_serdes or squash.number(4))
        end,
        OverlapParams = squash.OverlapParams,
        RaycastParams = squash.RaycastParams,
        Vector3 = function(number_serdes: squash.SerDes<number>?): squash.SerDes<Vector3>
            return squash.Vector3(number_serdes or squash.number(4))
        end,
        PathWaypoint = function(number_serdes: squash.SerDes<number>?): squash.SerDes<PathWaypoint>
            return squash.PathWaypoint(number_serdes or squash.number(4))
        end,
        PhysicalProperties = squash.PhysicalProperties,
        Ray = function(number_serdes: squash.SerDes<number>?): squash.SerDes<Ray>
            return squash.Ray(number_serdes or squash.number(4))
        end,
        RaycastResult = function(number_serdes: squash.SerDes<number>?): squash.SerDes<squash.SquashRaycastResult>
            return squash.RaycastResult(number_serdes or squash.number(4)) :: any
        end,
        Vector2 = function(number_serdes: squash.SerDes<number>?): squash.SerDes<Vector2>
            return squash.Vector2(number_serdes or squash.number(4))
        end,
        Rect = function(number_serdes: squash.SerDes<number>?): squash.SerDes<Rect>
            return squash.Rect(number_serdes or squash.number(4))
        end,
        Region3 = function(number_serdes: squash.SerDes<number>?): squash.SerDes<Region3>
            return squash.Region3(number_serdes or squash.number(4))
        end,
        Region3int16 = squash.Region3int16,
        RotationCurveKey = function(number_serdes: squash.SerDes<number>?): squash.SerDes<RotationCurveKey>
            return squash.RotationCurveKey(number_serdes or squash.number(4))
        end,
        TweenInfo = squash.TweenInfo,
        UDim = function(number_serdes: squash.SerDes<number>?): squash.SerDes<UDim>
            return squash.UDim(number_serdes or squash.number(4))
        end,
        UDim2 = function(number_serdes: squash.SerDes<number>?): squash.SerDes<UDim2>
            return squash.UDim2(number_serdes or squash.number(4))
        end,
        Vector2int16 = squash.Vector2int16,
        Vector3int16 = squash.Vector3int16,
        ["Instance"] = instance_serdes,
        unknown = unknown_serdes,
        ["nil"] = nil_serdes,
        literal = squash.literal,
        base_conversion = table.freeze({
            alphabet = squash.string.alphabet,
            convert = squash.string.convert,
            binary = squash.string.binary,
            octal = squash.string.octal,
            decimal = squash.string.decimal,
            duodecimal = squash.string.duodecimal,
            hexadecimal = squash.string.hexadecimal,
            utf8 = squash.string.utf8,
            lower = squash.string.lower,
            upper = squash.string.upper,
            letters = squash.string.letters,
            punctuation = squash.string.punctuation,
            english = squash.string.english,
            filepath = squash.string.filepath,
            datastore = squash.string.datastore,
        }),
    }),
    id_to_type = table.freeze({
        [1] = "boolean",
        [2] = "uint",
        [3] = "int",
        [4] = "number",
        [5] = "string",
        [6] = "buffer",
        [7] = "vlq",
        [8] = "opt",
        [9] = "array",
        [10] = "tuple",
        [11] = "record",
        [12] = "map",
        [13] = "table",
        [14] = "Axes",
        [15] = "BrickColor",
        [16] = "EnumItem",
        [17] = "CatalogueSearchParams",
        [18] = "CFrame",
        [19] = "Color3",
        [20] = "ColorSequenceKeypoint",
        [21] = "ColorSequence",
        [22] = "DateTime",
        [23] = "Faces",
        [24] = "FloatCurveKey",
        [25] = "Font",
        [26] = "NumberRange",
        [27] = "NumberSequenceKeypoint",
        [28] = "NumberSequence",
        [29] = "OverlapParams",
        [30] = "RaycastParams",
        [31] = "Vector3",
        [32] = "PathWaypoint",
        [33] = "PhysicalProperties",
        [34] = "Ray",
        [35] = "RaycastResult",
        [36] = "Vector2",
        [37] = "Rect",
        [38] = "Region3",
        [39] = "Region3int16",
        [40] = "RotationCurveKey",
        [41] = "TweenInfo",
        [42] = "UDim",
        [43] = "UDim2",
        [44] = "Vector2int16",
        [45] = "Vector3int16",
        [46] = "Instance",
        [47] = "nil",
        [48] = "literal",
        [49] = "EOF", -- End Of File
    }),
    type_to_id = table.freeze({
        boolean = 1,
        uint = 2,
        int = 3,
        number = 4,
        string = 5,
        buffer = 6,
        vlq = 7,
        opt = 8,
        array = 9,
        tuple = 10,
        record = 11,
        map = 12,
        table = 13,
        Axes = 14,
        BrickColor = 15,
        EnumItem = 16,
        CatalogueSearchParams = 17,
        CFrame = 18,
        Color3 = 19,
        ColorSequenceKeypoint = 20,
        ColorSequence = 21,
        DateTime = 22,
        Faces = 23,
        FloatCurveKey = 24,
        Font = 25,
        NumberRange = 26,
        NumberSequenceKeypoint = 27,
        NumberSequence = 28,
        OverlapParams = 29,
        RaycastParams = 30,
        Vector3 = 31,
        PathWaypoint = 32,
        PhysicalProperties = 33,
        Ray = 34,
        RaycastResult = 35,
        Vector2 = 36,
        Rect = 37,
        Region3 = 38,
        Region3int16 = 39,
        RotationCurveKey = 40,
        TweenInfo = 41,
        UDim = 42,
        UDim2 = 43,
        Vector2int16 = 44,
        Vector3int16 = 45,
        Instance = 46,
        ["nil"] = 47,
        literal = 48,
        EOF = 49, -- End Of File
    }),
    channel = create_channel,
    channel_from_buffer = create_channel_from_buffer,
})

return exports :: {
    types: { [string]: serdes<any> },
    id_to_type: { [number]: string },
    type_to_id: { [string]: number },
    channel: (size: number) -> channel,
    channel_from_buffer: (buf: buffer) -> channel,
}
