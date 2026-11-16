--!strict
-- Client entry point: starts the top-down camera, talking and chests in
-- villages, random fights in the wild, the checkpoint (last village
-- visited), and a battle when the player touches a fixed enemy.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Config = require(ReplicatedStorage.Modules.Config)
local Battle = require(script.Parent.Battle)
local Checkpoint = require(script.Parent.Checkpoint)
local Hud = require(script.Parent.Hud)
local EncounterTrigger = require(script.Parent.EncounterTrigger)
local RandomEncounters = require(script.Parent.RandomEncounters)
local TopDownCamera = require(script.Parent.TopDownCamera)
local Village = require(script.Parent.Village)

TopDownCamera.start()
EncounterTrigger.start(Battle.start)
Village.start()
Checkpoint.start()
Hud.start()
RandomEncounters.start()

print(`[{Config.GameName}] client running for {Players.LocalPlayer.Name}`)
