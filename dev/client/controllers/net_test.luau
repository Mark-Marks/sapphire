--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local events = require(ReplicatedStorage.events)
local fuzz = require(ReplicatedStorage.fuzz)
local sapphire_net = require(ReplicatedStorage.Packages.sapphire_net)

local reliable_event: sapphire_net.event<fuzz.person> = sapphire_net.undefined("person_reliable", "reliable")
local unreliable_event: sapphire_net.event<fuzz.person> = sapphire_net.undefined("person_unreliable", "unreliable")

local NetTest = {}
NetTest.priority = math.huge

local receive_count = 0

local function print_person(person: fuzz.person)
    if person == nil then
        return
    end
    --print(
    --    `[Client] Received person: name - {person.name}, age - {person.age}, height - {person.height}, sex - {person.sex}`
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

    for _ = 1, 1_000 do
        debug.profilebegin("[Client] Sending 4 static events")
        events.test_namespace.reliable_test_event.send(fuzz.fuzz_person())
        events.test_namespace.unreliable_test_event.send(fuzz.fuzz_person())
        events.test_namespace_two.reliable_test_event.send(fuzz.fuzz_person())
        events.test_namespace_two.unreliable_test_event.send(fuzz.fuzz_person())
        debug.profileend()

        debug.profilebegin("[Client] Sending 2 dynamic events")
        reliable_event.send(fuzz.fuzz_person())
        unreliable_event.send(fuzz.fuzz_person())
        debug.profileend()
    end

    task.wait(15)
    print(`[Client] Total receive count: {receive_count}`)
end

function NetTest.on_heartbeat(delta_time: number)
    for _, data in events.test_namespace.reliable_test_event.next() do
        print_person(data)
    end
    for _, data in events.test_namespace.unreliable_test_event.next() do
        print_person(data)
    end
    for _, data in events.test_namespace_two.reliable_test_event.next() do
        print_person(data)
    end
    for _, data in events.test_namespace_two.unreliable_test_event.next() do
        print_person(data)
    end
    for _, data in reliable_event.next() do
        print_person(data)
    end
    for _, data in unreliable_event.next() do
        print_person(data)
    end
end

return NetTest
