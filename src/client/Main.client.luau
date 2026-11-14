--!strict
-- Client entry point: starts the top-down camera and starts a battle when
-- the player touches an enemy.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Config = require(ReplicatedStorage.Modules.Config)
local Battle = require(script.Parent.Battle)
local EncounterTrigger = require(script.Parent.EncounterTrigger)
local TopDownCamera = require(script.Parent.TopDownCamera)

TopDownCamera.start()
EncounterTrigger.start(Battle.start)

print(`[{Config.GameName}] client running for {Players.LocalPlayer.Name}`)
