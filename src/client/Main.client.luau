--!strict
-- Client entry point: starts the top-down camera and listens for enemy
-- encounters.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Config = require(ReplicatedStorage.Modules.Config)
local Enemies = require(ReplicatedStorage.Modules.Enemies)
local EncounterTrigger = require(script.Parent.EncounterTrigger)
local TopDownCamera = require(script.Parent.TopDownCamera)

TopDownCamera.start()

-- Temporary until step 3 (battle transition): show a banner so we can see
-- that touching an enemy starts a battle.
local banner: TextLabel
do
	local gui = Instance.new("ScreenGui")
	gui.Name = "EncounterBanner"
	gui.ResetOnSpawn = false
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

	banner = Instance.new("TextLabel")
	banner.AnchorPoint = Vector2.new(0.5, 0)
	banner.Position = UDim2.new(0.5, 0, 0, 24)
	banner.Size = UDim2.fromOffset(360, 56)
	banner.BackgroundColor3 = Color3.new(0, 0, 0)
	banner.BackgroundTransparency = 0.2
	banner.TextColor3 = Color3.new(1, 1, 1)
	banner.Font = Enum.Font.Arcade
	banner.TextSize = 28
	banner.Visible = false
	banner.Parent = gui
end

EncounterTrigger.start(function(enemyId: string, _enemyModel: Model)
	local data = Enemies[enemyId]
	local name = if data then data.DisplayName else enemyId
	print(`[{Config.GameName}] battle starts: {name}`)

	banner.Text = `* {name} blocks the way!`
	banner.Visible = true
	task.delay(2, function()
		banner.Visible = false
	end)
end)

print(`[{Config.GameName}] client running for {Players.LocalPlayer.Name}`)
