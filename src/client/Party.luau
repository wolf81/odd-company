--!strict
-- The player's team: allies who joined, in the order they joined, at most
-- Config.MaxTeamSize. They walk in a line behind the player. An ally who
-- is sent away goes back to where they stood in the village and can be
-- recruited again. Client-only like the battle, and forgotten when you
-- leave the game (saving comes in the Systems phase).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AllyTypes = require(ReplicatedStorage.Modules.Allies.AllyTypes)
local Config = require(ReplicatedStorage.Modules.Config)
local AllyFollow = require(script.Parent.AllyFollow)

local Party = {}

type Member = {
	data: AllyTypes.AllyData,
	model: Model,
	home: CFrame, -- where they stood in the village
	prompt: ProximityPrompt, -- their Talk prompt, off while in the team
	stopFollowing: () -> (),
}

local members: { Member } = {}

local function playerPosition(): Vector3?
	local character = Players.LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	return if root then root.Position else nil
end

-- (Re)starts the line: the first ally follows the player, every next ally
-- follows the one in front of them.
local function rebuildLine()
	local leader: () -> Vector3? = playerPosition
	for _, member in members do
		member.stopFollowing()
		member.stopFollowing = AllyFollow.start(member.model, member.data.WalkAnimationId, leader)
		local model = member.model
		leader = function()
			return if model.Parent then model:GetPivot().Position else nil
		end
	end
end

-- The allies in the team, in the order they joined.
function Party.allies(): { AllyTypes.AllyData }
	local list = {}
	for _, member in members do
		table.insert(list, member.data)
	end
	return list
end

function Party.has(id: string): boolean
	for _, member in members do
		if member.data.Id == id then
			return true
		end
	end
	return false
end

function Party.isFull(): boolean
	return #members >= Config.MaxTeamSize
end

-- `model` is the ally's rig in the village, `prompt` their Talk prompt.
-- Check Party.isFull() first.
function Party.join(data: AllyTypes.AllyData, model: Model, prompt: ProximityPrompt)
	prompt.Enabled = false -- they follow you now; no more talking
	table.insert(members, {
		data = data,
		model = model,
		home = model:GetPivot(),
		prompt = prompt,
		stopFollowing = function() end,
	})
	rebuildLine()
end

-- Sends an ally back to their spot in the village.
function Party.remove(id: string)
	for i, member in members do
		if member.data.Id == id then
			member.stopFollowing()
			member.model:PivotTo(member.home)
			member.prompt.Enabled = true
			table.remove(members, i)
			rebuildLine()
			return
		end
	end
end

return Party
