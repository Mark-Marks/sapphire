--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local events = require(ReplicatedStorage.events)
local fuzz = require(ReplicatedStorage.fuzz)
local sapphire_net = require(ReplicatedStorage.Packages.sapphire_net)

local reliable_event: sapphire_net.event<fuzz.person> = sapphire_net.undefined("person_reliable", "reliable")
local unreliable_event: sapphire_net.event<fuzz.person> = sapphire_net.undefined("person_unreliable", "unreliable")

local NetTest = {}
NetTest.priority = math.huge

local receive_count = 0

local function print_person(person: fuzz.person, player: Player?)
    if person == nil then
        return
    end
    assert(player, "[Server] Player doesn't exist wtf?")
    --print(
    --    `[Server] Received person from {player.Name}: name - {person.name}, age - {person.age}, height - {person.height}, sex - {person.sex}`
    --)
    receive_count += 1
end

function NetTest.start()
    events.test_namespace.reliable_test_event.listen(print_person)
    events.test_namespace.unreliable_test_event.listen(print_person)
    events.test_namespace_two.reliable_test_event.listen(print_person)
    events.test_namespace_two.unreliable_test_event.listen(print_person)

    reliable_event.listen(print_person)
    unreliable_event.listen(print_person)

    Players.PlayerAdded:Connect(function(player)
        print("fuck you i ran before you")
        for _ = 1, 1 do
            debug.profilebegin("[Server] Sending 4 static events")
            events.test_namespace.reliable_test_event.send_to(player, fuzz.fuzz_person())
            events.test_namespace.unreliable_test_event.send_to(player, fuzz.fuzz_person())
            events.test_namespace_two.reliable_test_event.send_to(player, fuzz.fuzz_person())
            events.test_namespace_two.unreliable_test_event.send_to(player, fuzz.fuzz_person())
            debug.profileend()

            debug.profilebegin("[Server] Sending 2 dynamic events")
            reliable_event.send_to(player, fuzz.fuzz_person())
            unreliable_event.send_to(player, fuzz.fuzz_person())
            debug.profileend()
        end
    end)

    task.wait(15)
    print(`[Server] Total receive count: {receive_count}`)
end

function NetTest.on_heartbeat(delta_time: number)
    for _, data, player in events.test_namespace.reliable_test_event.next() do
        print_person(data, player)
    end
    for _, data, player in events.test_namespace.unreliable_test_event.next() do
        print_person(data, player)
    end
    for _, data, player in events.test_namespace_two.reliable_test_event.next() do
        print_person(data, player)
    end
    for _, data, player in events.test_namespace_two.unreliable_test_event.next() do
        print_person(data, player)
    end
    for _, data, player in reliable_event.next() do
        print_person(data, player)
    end
    for _, data, player in unreliable_event.next() do
        print_person(data, player)
    end
end

return NetTest
