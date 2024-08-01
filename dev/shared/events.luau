local ReplicatedStorage = game:GetService("ReplicatedStorage")

local sapphire_net = require(ReplicatedStorage.Packages.sapphire_net)
local t = sapphire_net.data_types

return {
    test_namespace = sapphire_net.define_namespace("test_namespace", function()
        return {
            reliable_test_event = sapphire_net.defined({
                value = t.record({
                    name = t.string(20),
                    age = t.uint(1),
                    height = t.uint(1),
                    sex = t.string(6),
                }),
            }),
            unreliable_test_event = sapphire_net.defined({
                value = t.record({
                    name = t.string(20),
                    age = t.uint(1),
                    height = t.uint(1),
                    sex = t.string(6),
                }),
                reliability_type = "unreliable",
            }),
        }
    end),
    test_namespace_two = sapphire_net.define_namespace("test_namespace_two", function()
        return {
            reliable_test_event = sapphire_net.defined({
                value = t.record({
                    name = t.string(20),
                    age = t.uint(1),
                    height = t.uint(1),
                    sex = t.string(6),
                }),
            }),
            unreliable_test_event = sapphire_net.defined({
                value = t.record({
                    name = t.string(20),
                    age = t.uint(1),
                    height = t.uint(1),
                    sex = t.string(6),
                }),
                reliability_type = "unreliable",
            }),
        }
    end),
}
