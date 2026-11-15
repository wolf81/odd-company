--!strict
-- Builds enemy avatars from their data and places them in a room, each
-- with an invisible trigger box that starts a battle.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Modules.Config)
local EnemyTypes = require(ReplicatedStorage.Modules.Enemies.EnemyTypes)
local AvatarBuilder = require(script.Parent.AvatarBuilder)

local EnemyBuilder = {}

-- Creates the enemy standing on `floorPosition`, facing south (toward the
-- camera), and parents it to `parent`. Returns the enemy model.
function EnemyBuilder.spawn(data: EnemyTypes.EnemyData, floorPosition: Vector3, parent: Instance): Model
	local model = AvatarBuilder.build(data.Id, data.Avatar, data.RigType, floorPosition)
	model:SetAttribute("EnemyId", data.Id)

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

return EnemyBuilder
