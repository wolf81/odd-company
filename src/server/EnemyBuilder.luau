--!strict
-- Builds enemy avatars from their data and places them in the world, each
-- with an invisible trigger box that starts a battle.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Modules.Config)
local EnemyTypes = require(ReplicatedStorage.Modules.Enemies.EnemyTypes)
local AvatarBuilder = require(script.Parent.AvatarBuilder)

local EnemyBuilder = {}

-- Creates the enemy standing on `floorPosition`, facing south (toward the
-- camera), and parents it to `parent`. Returns the enemy model.
-- `group` (optional): enemies with the same group fight together.
function EnemyBuilder.spawn(data: EnemyTypes.EnemyData, floorPosition: Vector3, parent: Instance, group: string?): Model
	local model = AvatarBuilder.build(data.Id, data.Avatar, data.RigType, floorPosition)
	model:SetAttribute("EnemyId", data.Id)
	if group then
		model:SetAttribute("EncounterGroup", group)
	end

	-- Invisible box a bit larger than the avatar. Touching it starts the
	-- battle, so even a big avatar triggers it before getting stuck.
	local boxCFrame, boxSize = model:GetBoundingBox()
	local trigger = Instance.new("Part")
	trigger.Name = "EncounterTrigger"
	trigger.Anchored = true
	trigger.CanCollide = false
	trigger.CanQuery = false
	trigger.Transparency = 1
	trigger.Size = boxSize + Vector3.new(2, 0, 2) * Config.EncounterTriggerPadding
	trigger.CFrame = boxCFrame
	trigger:SetAttribute("EnemyId", data.Id)
	CollectionService:AddTag(trigger, Config.EnemyTriggerTag)
	trigger.Parent = model

	model.Parent = parent
	AvatarBuilder.playIdle(model, data.IdleAnimationId)
	return model
end

-- Builds one copy of every enemy (no trigger box) into `folder`, named by
-- Id. Random fights copy these into the battle arena.
function EnemyBuilder.buildTemplates(enemies: { [string]: EnemyTypes.EnemyData }, folder: Instance)
	for id, data in enemies do
		local model = AvatarBuilder.build(id, data.Avatar, data.RigType, Vector3.zero)
		model:SetAttribute("EnemyId", id)
		model.Parent = folder
	end
end

return EnemyBuilder
