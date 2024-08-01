--!strict
--!native
--!optimize 2
local squash = require(script.Parent.Parent.squash)

return table.freeze({
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
        --- REIMPLEMENT THIS
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
        [46] = "EOF", -- End Of File
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
        EOF = 46, -- End Of File
    }),
})
