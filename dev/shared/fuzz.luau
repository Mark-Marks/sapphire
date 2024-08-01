local HttpService = game:GetService("HttpService")

local function generate_cut_string(length: number): string
    local str = HttpService:GenerateGUID(false)
    return string.sub(str, 1, length)
end

local function get_random_choice<T>(...: T): T
    local choices = { ... }
    return choices[math.random(1, #choices)]
end

export type person = {
    name: string,
    age: number,
    height: number,
    sex: string,
}

local function fuzz_person(): person
    return {
        name = generate_cut_string(20),
        age = math.random(1, 2 ^ 8 - 1),
        height = math.random(1, 2 ^ 8 - 1),
        sex = get_random_choice("male", "female"),
    }
end

return {
    generate_cut_string = generate_cut_string,
    get_random_choice = get_random_choice,
    fuzz_person = fuzz_person,
}
