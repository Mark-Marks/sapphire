local ReplicatedStorage = game:GetService("ReplicatedStorage")

local sapphire_net = require(ReplicatedStorage.Packages.sapphire_net)
local t = sapphire_net.data_types
local f64 = t.number(8)

return {
    data_replication = sapphire_net.define_namespace("data_replication", function()
        return {
            jecs_world = sapphire_net.defined({
                value = t.record({
                    added = t.map(f64, t.array(f64)),
                    set = t.map(f64, t.map(f64, t.unknown())),
                    removed = t.map(f64, t.array(f64)),
                }),
                reliability_type = "reliable",
            }),
            loaded = sapphire_net.defined({
                value = t["nil"](),
                reliability_type = "reliable",
            }),
        }
    end),
}
