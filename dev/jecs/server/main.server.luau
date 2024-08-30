--!strict
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local sapphire = require(ReplicatedStorage.Packages.sapphire)()
local sapphire_jecs = require(ReplicatedStorage.Packages.sapphire_jecs)
local sapphire_net = require(ReplicatedStorage.Packages.sapphire_net)

local services = ServerScriptService.services
local systems = services.systems

sapphire:use(sapphire_net):use(sapphire_jecs):register_singletons(services):register_singletons(systems):start()
