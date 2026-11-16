--!strict
-- Remembers the last village the player walked into. Losing a battle
-- sends you back to that village's spawn (the start village at first).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Areas = require(ReplicatedStorage.Modules.World.Areas)
local Ground = require(ReplicatedStorage.Modules.World.Ground)
local World = require(ReplicatedStorage.Modules.World)

local Checkpoint = {}

local startVillage = Areas.village(World.StartVillage)
local current: Vector3 = if startVillage then startVillage.Spawn else Vector3.zero

-- Where to restart after losing (on the ground at the village spawn).
function Checkpoint.position(): Vector3
	return Ground.at(current)
end

-- Checks twice a second which village (if any) the player is in.
function Checkpoint.start()
	task.spawn(function()
		while true do
			local character = Players.LocalPlayer.Character
			local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
			local village = root and Areas.villageAt(root.Position)
			if village then
				current = village.Spawn
			end
			task.wait(0.5)
		end
	end)
end

return Checkpoint
