--!strict
local StarterPlayer = game:GetService("StarterPlayer")
local StarterPlayerScripts = StarterPlayer.StarterPlayerScripts
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local sapphire = require(ReplicatedStorage.Packages.sapphire)()
local sapphire_jecs = require(ReplicatedStorage.Packages.sapphire_jecs)
local sapphire_net = require(ReplicatedStorage.Packages.sapphire_net)

local controllers = StarterPlayerScripts.controllers
local systems = controllers.systems

sapphire:use(sapphire_net):use(sapphire_jecs):register_singletons(controllers):register_singletons(systems):start()
