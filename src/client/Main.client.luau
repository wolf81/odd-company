--!strict
-- Client entry point: starts the top-down camera.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Config = require(ReplicatedStorage.Modules.Config)
local TopDownCamera = require(script.Parent.TopDownCamera)

TopDownCamera.start()

print(`[{Config.GameName}] client running for {Players.LocalPlayer.Name}`)
