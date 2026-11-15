--!strict
-- Client entry point: starts the top-down camera, talking and chests in the
-- village, and starts a battle when the player touches an enemy.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Config = require(ReplicatedStorage.Modules.Config)
local Battle = require(script.Parent.Battle)
local EncounterTrigger = require(script.Parent.EncounterTrigger)
local TopDownCamera = require(script.Parent.TopDownCamera)
local Village = require(script.Parent.Village)

TopDownCamera.start()
EncounterTrigger.start(Battle.start)
Village.start()

print(`[{Config.GameName}] client running for {Players.LocalPlayer.Name}`)
