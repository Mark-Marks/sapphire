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
            loaded = sapphire_net.defined({
                value = t.boolean(),
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
    data_replication = sapphire_net.define_namespace("data_replication", function()
        return {
            ecr_registry = sapphire_net.defined({
                value = t.map(t.uint(4), t.map(t.uint(4), t.unknown())),
                reliability_type = "reliable",
            }),
        }
    end),
}
