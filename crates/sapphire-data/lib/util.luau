--!strict
local function deep_clone<T>(t: T): T
    local res = table.clone(t :: T & {})

    for key, value in res do
        if typeof(value) == "table" then
            res[key] = deep_clone(value)
            continue
        end
    end

    return res :: T & {}
end

local function deep_freeze<T>(t: T): T
    local res = table.freeze(t :: T & {})

    for key, value in res do
        if typeof(value) == "table" then
            res[key] = deep_freeze(value)
            continue
        end
    end

    return res :: T & {}
end

local function reconcile<T>(original: { [any]: any }, template: T & {}): T
    local res = table.clone(original)

    for key, value in template :: {} do
        if not res[key] then
            if typeof(value) == "table" then
                res[key] = deep_clone(value)
                continue
            end

            res[key] = value
            continue
        end

        if typeof(value) == "table" then
            res[key] = reconcile(res[key], value :: any)
            continue
        end
    end

    return res :: T & {}
end

return {
    deep_clone = deep_clone,
    deep_freeze = deep_freeze,
    reconcile = reconcile,
}
