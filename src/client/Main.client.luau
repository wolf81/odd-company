--!strict
-- Client entry point. For now it only proves that Rojo sync works:
-- you should see this message in Studio's Output window when you press Play.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Config = require(ReplicatedStorage.Modules.Config)

print(`[{Config.GameName}] client running for {Players.LocalPlayer.Name}`)
